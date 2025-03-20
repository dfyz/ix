{% extends '//lib/compiler_rt/t/ix.sh' %}

{% block fetch %}
{% include '//lib/llvm/19/ver.sh' %}
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

# Force using the fast unwinder. The slow unwinder uses `libunwind`,
# which introduces circular dependencies when building `lib/c++`.
# We compile sanitized binaries with `-fno-omit-frame-pointer`,
# so the fast unwinder should work fine.
sed -i \
    's/define SANITIZER_CAN_SLOW_UNWIND 1/define SANITIZER_CAN_SLOW_UNWIND 0/' \
    compiler-rt/lib/sanitizer_common/sanitizer_stacktrace.h

# Create stubs for:
#   * the `libunwind` functions used by the slow unwinder
#   * `dlsym()` (TODO: implement a `dlsym()` that can be used for interception)
sed -i \
  '/SANITIZER_SOURCES_NOTERMINATION/a sanitizer_fakes.cpp' \
  compiler-rt/lib/sanitizer_common/CMakeLists.txt

cat << EOF > compiler-rt/lib/sanitizer_common/sanitizer_fakes.cpp
#include <stdio.h>
#include <stdlib.h>

#define _GNU_SOURCE 1
#include <unwind.h>

extern "C" {
  void* {{uniq_id}}_dlsym(void* handle, const char* symbol) { return NULL; }

  uintptr_t {{uniq_id}}__Unwind_GetIP(struct _Unwind_Context*) {
    fprintf(stderr, "_Unwind_GetIP() was not supposed to be called\n");
    abort();
  }

  _Unwind_Reason_Code {{uniq_id}}__Unwind_Backtrace(_Unwind_Trace_Fn, void *) {
    fprintf(stderr, "_Unwind_Backtrace() was not supposed to be called\n");
    abort();
  }
}
EOF
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

{% block env %}
export LDFLAGS="-resource-dir=${out} \${LDFLAGS}"
{% endblock %}

{% block install %}
{{super()}}
mkdir -p ${out}/include
cp -R compiler-rt/include/sanitizer ${out}/include
{% endblock %}

{% block c_rename_symbol %}
_Unwind_GetIP
_Unwind_Backtrace
dlsym
{% endblock %}
