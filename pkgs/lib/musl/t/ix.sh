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
{% if sanitize == 'address' %}
sed -e '/int main();/a void __asan_init();' -e '/int argc =/i __asan_init();' -i crt/crt1.c
{% endif %}
{% endblock %}

{% block install %}
{{super()}}
cd ${out}/lib
ar q libcrt.a crt1.o crti.o crtn.o
ranlib libcrt.a
{% if sanitize %}
find ${out}/lib -name '*.a' -or -name '*.o' | while read l
do
	llvm-objcopy --redefine-syms=${SANITIZER_SYMBOLS_TO_REDEFINE} ${l}
done
{% endif %}
{% endblock %}

{% block env %}
export CMFLAGS="-DLIBCXX_HAS_MUSL_LIBC=yes \${CMFLAGS}"
export CPPFLAGS="${PICFLAGS} -D_LARGEFILE64_SOURCE=1 -isystem ${out}/include \${CPPFLAGS}"
export LDFLAGS="-static \${LDFLAGS}"
{% endblock %}
