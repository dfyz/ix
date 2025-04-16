{% extends '//lib/compiler_rt/t/ix.sh' %}

{% block fetch %}
{# LLVM 20 contains this important commit: https://github.com/llvm/llvm-project/pull/108913 #}
{% include '//lib/llvm/20/ver.sh' %}
{% endblock %}

{% block patch %}
{{super()}}
# Ignore any attempts to build shared sanitizers.
sed -i \
  '/function(add_compiler_rt_runtime name type)/a if(type MATCHES "^SHARED$")\n  return()\nendif()' \
  compiler-rt/cmake/Modules/AddCompilerRT.cmake

# Convert `DoesNotSupportStaticLinking()` into a no-op, since we are going to use static linking anyway.
sed -i \
  '/volatile auto x = &kDynamic;/d' \
  compiler-rt/lib/interception/interception.h

# Intercept the function at compile-time instead of run-time.
sed -i \
'
/#endif.*INTERCEPTION_LINUX_H/i\
#undef INTERCEPT_FUNCTION_LINUX_OR_FREEBSD\
#define INTERCEPT_FUNCTION_LINUX_OR_FREEBSD(func) (REAL(func) = &__real_##func)
' \
  compiler-rt/lib/interception/interception_linux.h

sed -i \
'
/# define DECLARE_REAL(ret_type, func, ...)            \\\|#  define DEFINE_REAL(ret_type, func, ...)            \\/a\
    extern "C" ret_type __real_##func(__VA_ARGS__); \\
' \
  compiler-rt/lib/interception/interception.h

# With compile-time binding, dlsym() is not used and can be stubbed.
# Also, the sanitizer runtime wants to call `{get,set}rlimit()`
# during the initialization for various reasons. This happens
# before the shadow memory is set up, so we need to use non-instrumented
# versions of these functions.
sed -i \
  '/SANITIZER_SOURCES_NOTERMINATION/a sanitizer_fakes.cpp' \
  compiler-rt/lib/sanitizer_common/CMakeLists.txt

cat << 'EOF' > compiler-rt/lib/sanitizer_common/sanitizer_fakes.cpp
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>
extern "C" {
  void* {{uniq_id}}_dlsym(void* handle, const char* symbol) {
    // Called from `InitializeSwiftDemangler()` in `compiler-rt/lib/sanitizer_common/sanitizer_symbolizer_posix_libcdep.cpp`
    bool known_call = handle == nullptr && strcmp(symbol, "swift_demangle") == 0;
    if (!known_call) {
      fprintf(stderr, "dlsym() was not supposed to be called with %p:%s\n", handle, symbol);
      abort();
    }
    return nullptr;
  }
  int {{uniq_id}}_getrlimit(int resource, void* rlim) {
    return syscall(SYS_getrlimit, resource, rlim);
  }
  int {{uniq_id}}_setrlimit(int resource, const void* rlim) {
    return syscall(SYS_setrlimit, resource, rlim);
  }
}
EOF

# `__dn_comp` is called `dn_comp` in musl.
sed -i \
  's/define DN_COMP_INTERCEPTOR_NAME __dn_comp/define DN_COMP_INTERCEPTOR_NAME dn_comp/' \
  compiler-rt/lib/sanitizer_common/sanitizer_common_interceptors.inc
{% endblock %}

{% block cmake_flags %}
{{super()}}
COMPILER_RT_BUILD_BUILTINS=OFF
COMPILER_RT_BUILD_SANITIZERS=ON
COMPILER_RT_BUILD_XRAY=OFF
COMPILER_RT_BUILD_LIBFUZZER=OFF
COMPILER_RT_BUILD_PROFILE=OFF
COMPILER_RT_BUILD_CTX_PROFILE=OFF
COMPILER_RT_BUILD_MEMPROF=OFF
COMPILER_RT_BUILD_ORC=OFF
COMPILER_RT_BUILD_GWP_ASAN=OFF
{% endblock %}

{% block cpp_includes %}
{{super()}}
${PWD}/compiler-rt/include
{% endblock %}

{% block c_rename_symbol %}
dlsym
getrlimit
setrlimit
{% endblock %}

{% block env %}
export LDFLAGS="-resource-dir=${out} \${LDFLAGS}"
export SANITIZER_SYMBOLS_TO_REDEFINE="${out}/lib/aux/symbols_to_redefine.txt"
{% endblock %}

{% block install %}
{{super()}}
mkdir -p ${out}/include
cp -R compiler-rt/include/sanitizer ${out}/include

find ${out}/lib -name '*.a' \
  | xargs llvm-nm -j \
  | sed -n '/^___interceptor_/ {
    s/^___interceptor_//
    # dlopen()/dlclose() are obviously not present in IX
    # pthread_mutexattr_getprioceiling() is present in POSIX, but not in musl
    # pthread_mutexattr_getrobust_np() is a GNU extension, so not present in musl
    # __b64_ntop()/__b64_pton() are not present in musl
    /^dlopen\|dlclose\|\(pthread_mutexattr_\(getprioceiling\|getrobust_np\)\)\|\(__b64_\(ntop\|pton\)\)$/ {
      w non_intercepted_symbols.txt
      b
    }
    w intercepted_symbols.txt
  }'

for fn in intercepted_symbols.txt non_intercepted_symbols.txt
do
  sort -u -o ${fn} ${fn}
done

sed 's/.*/void __real_&(){}/' non_intercepted_symbols.txt > fake_reals.c
cc -O2 -c fake_reals.c
ar qs $(find ${out}/lib -name '*libclang_rt.asan-*' | head -n1) fake_reals.o

# We always want to use the intercepted function handlers, so make them non-weak.
find ${out}/lib -name '*.a' | while read l
do
  llvm-objcopy \
    --strip-symbols=non_intercepted_symbols.txt \
    --globalize-symbols=intercepted_symbols.txt \
    ${l}
done

# Any library that wants to define any of the intercepted symbols has to go through this redefinition list.
mkdir -p ${out}/share
sed 's/.*/& __real_&/' intercepted_symbols.txt > ${out}/share/symbols_to_redefine.txt
{% endblock %}
