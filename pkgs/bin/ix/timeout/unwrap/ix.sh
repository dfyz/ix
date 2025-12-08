{% extends '//die/c/autohell.sh' %}

{% block fetch %}
{# FIXME: upgrade this back to 9.9 after cross-compilation issues are solved #}
https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.gz
767ae6a22950ec42f3ba5f7c1de79dd27800ee8e9b8642da5dedb5974a1741e5
{% endblock %}

{% block bld_libs %}
lib/tiny
lib/kernel
lib/musl/env
{% endblock %}

{% block configure_flags %}
--enable-install-program=timeout
{% endblock %}

{% block install %}
mkdir ${out}/bin
cp src/timeout ${out}/bin/
{% endblock %}
