{% extends '//lib/compiler_rt/sanitize/t/ix.sh' %}

{% block sanitizer_name %}msan{% endblock %}

{% block non_intercepted_symbols %}
{{super()}}
{# IX doesn't need/have dl*() functions #}
dladdr
dlerror
{# musl doesn't implement any of the below functions #}
__libc_memalign
__strdup
mallinfo
strtouq
wmempcpy
{#
`__getrlimit()` is not present in musl, and `getrlimit64()`/`prlimit64()`
are just aliases for `getrlimit()`/`prlimit()`.
#}
__getrlimit
getrlimit64
prlimit64
{% endblock %}

{% block patch %}
{{super()}}
# msan tries to intercept additional variants of `strto*()` functions, which musl doesn't have.
# Instead of enumerating them all in the `non_intercepted_symbols` block, remove this interception from the source.
sed -i \
  's/INTERCEPT_FUNCTION(func##_l)\|INTERCEPT_FUNCTION(__##func##_l)\|INTERCEPT_FUNCTION(__##func##_internal)//' \
  compiler-rt/lib/msan/msan_interceptors.cpp

# This symbol was gated by `#if SANITIZER_GLIBC` in
# https://github.com/llvm/llvm-project/commit/a5519b99bc73d50f362d6fb306411e9fcb758b53
# However, it is still mistakenly used by the `getrlimit64()`/`prlimit64()` interceptors,
# which are not gated. Patch the references to this symbols directly in the source.
sed -i \
  's/__sanitizer::struct_rlimit64_sz/0/' \
  compiler-rt/lib/msan/msan_interceptors.cpp
{% endblock %}
