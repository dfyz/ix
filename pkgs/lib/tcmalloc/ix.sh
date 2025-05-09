{% extends '//die/c/ix.sh' %}

{% block fetch %}
https://github.com/google/tcmalloc/archive/432d115adab8935b0a937d659c345aa8f82add57.tar.gz
sha:a5480b4012f0e36ab03f47479c8ba2f27ea70607156825266e3da84f6a28caf9
{% endblock %}

{% block lib_deps %}
lib/abseil/cpp
lib/tcmalloc/headers
lib/build/w/include/next
{% endblock %}

{% block bld_libs %}
lib/kernel
{% endblock %}

{% block cpp_includes %}
${PWD}
{% endblock %}

{% block cpp_defines %}
TCMALLOC_INTERNAL_8K_PAGES
{% endblock %}

{% block patch %}
find . -type f -name '*_test.*' -delete
find . -type f -name '*_fuzz.*' -delete
find . -type f -name '*_benchmark.*' -delete
find . -type f -name '*mock_*' -delete
rm tcmalloc/internal/profile_builder.cc
rm tcmalloc/profile_marshaler.cc
rm -rf tcmalloc/testing
{% endblock %}

{% block build %}
set -x
echo 'tcmalloc/internal/percpu_rseq_asm.S' | while read l; do
    c++ -c ${l} -o ${l}.o
done
find tcmalloc -type f -name '*.cc' | grep -v 'want_' | while read l; do
    c++ -c ${l} -o ${l}.o
done
ar q libtcmalloc.a $(find . -type f -name '*.o')
{% endblock %}

{% block install %}
mkdir ${out}/lib
cp libtcmalloc.a ${out}/lib/
{% if sanitize %}
llvm-objcopy --redefine-syms=${SANITIZER_SYMBOLS_TO_REDEFINE} ${out}/lib/libtcmalloc.a
{% endif %}
{% endblock %}

{% block env %}
export ac_cv_func_reallocarray=yes
export ac_cv_func_malloc_0_nonnull=yes
export ac_cv_func_realloc_0_nonnull=yes
{% endblock %}
