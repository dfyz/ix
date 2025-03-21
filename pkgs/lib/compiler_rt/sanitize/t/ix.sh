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

# Create weak symbols to trick CMake into compiling its "simple test programs".
sed -i \
  '/SANITIZER_SOURCES_NOTERMINATION/a sanitizer_fakes.cpp' \
  compiler-rt/lib/sanitizer_common/CMakeLists.txt

base64 -d << EOF > compiler-rt/lib/sanitizer_common/sanitizer_fakes.cpp
{% include 'fakes.cpp/base64' %}
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
