{% extends '//die/c/configure.sh' %}

{% block pkg_name %}
musl
{% endblock %}

{% block version %}
1.2.5
{% endblock %}

{% block fetch %}
http://musl.libc.org/releases/musl-{{self.version().strip()}}.tar.gz
sha:a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4
{% endblock %}

{% block lib_deps %}
lib/build
lib/musl/env
{% endblock %}

{% block configure_script %}
./configure
{% endblock %}

{% block configure_flags %}
--target={{target.gnu.three}}
--host={{target.gnu.three}}
--build={{host.gnu.three}}
--enable-static
--disable-shared
{% endblock %}

{% block setup_target_flags %}
export PICFLAGS="-fno-pic -fno-pie"
export CPPFLAGS="${PICFLAGS} ${CPPFLAGS}"
{% endblock %}

{% block patch %}
cat << EOF > src/stdlib/dso_handle.c
void* __dso_handle = (void*)&__dso_handle;
EOF
{% if sanitize %}
# String functions in musl intentionally do OOB reads:
# https://inbox.vuxu.org/musl/20160105164640.GL23362@port70.net/
# This is obviously a problem for sanitizers.
# Thankfully, the problematic patterns are gated with `__GNUC__`,
# so we can disable them here.
for file in memccpy memchr stpcpy stpncpy strchrnul strlcpy strlen
do
  sed -i \
    's/#ifdef __GNUC__/#ifdef PLZ_NO_UNSAFE_SHENANIGANS/' \
    src/string/${file}.c
done

# Avoid instrumenting libc initialization functions that
# are called before the sanitizer runtime is initialized.
#
# It is tempting to use `-fsanitize-ignorelist=...` for
# this purpose, but it is not enough for some sanitizers
# such as MemorySanitizer: they will not report ignored
# functions, but will still instrument them.
PLZ_NO_SAN="__attribute__((disable_sanitizer_instrumentation))"
sed -i \
  "/int __init_tp\|void \*__copy_tls\|void static_init_tls/i ${PLZ_NO_SAN}" \
  src/env/__init_tls.c
sed -i \
  "/void __init_libc\|void libc_start_init\|int __libc_start_main\|int libc_start_main_stage2/i ${PLZ_NO_SAN}" \
  src/env/__libc_start_main.c
sed -i \
  "/void __init_ssp\|void __stack_chk_fail/i ${PLZ_NO_SAN}" \
  src/env/__stack_chk_fail.c
sed -i \
  "/void _start_c/i ${PLZ_NO_SAN}" \
  crt/crt1.c
# Also, the sanitizer runtime wants to call `{get,set}rlimit()`
# during the initialization for various reasons. This happens
# before the shadow memory is set up, so we need to use
# non-instrumented versions of these functions.
sed -i \
  "/int getrlimit/i ${PLZ_NO_SAN}" \
  src/misc/getrlimit.c
sed -i \
  "/int setrlimit\|void do_setrlimit/i ${PLZ_NO_SAN}" \
  src/misc/setrlimit.c
{% endif %}
{% endblock %}

{% block install %}
{{super()}}
cd ${out}/lib
ar q libcrt.a crt1.o crti.o crtn.o
ranlib libcrt.a
{% if sanitize %}
find ${out}/lib \
  '(' -name '*.a' -or -name '*.o' ')' \
  -exec ${IX_SANITIZER_SYMBOL_REDEFINER} '{}' ';'
{% endif %}
{% endblock %}

{% block env %}
export CMFLAGS="-DLIBCXX_HAS_MUSL_LIBC=yes \${CMFLAGS}"
export CPPFLAGS="${PICFLAGS} -D_LARGEFILE64_SOURCE=1 -isystem ${out}/include \${CPPFLAGS}"
export LDFLAGS="-static \${LDFLAGS}"
{% endblock %}
