{% extends '//die/c/autorehell.sh' %}

{% block pkg_name %}
tor
{% endblock %}

{% block version %}
0.4.8.16
{% endblock %}

{% block fetch %}
https://gitlab.torproject.org/tpo/core/tor/-/archive/tor-{{self.version().strip()}}/tor-tor-{{self.version().strip()}}.tar.bz2
sha:c8aaf88de08bc03d16dccd94a6fe93b313d7b3c01b31c79a8bdc2b6e20c928be
{% endblock %}

{% block bld_libs %}
lib/c
lib/z
lib/xz
lib/cap
lib/zstd
lib/event
lib/seccomp
lib/bsd/overlay
{% endblock %}

{% block configure_flags %}
--enable-lzma
--enable-zstd
--disable-asciidoc
{% endblock %}

{% block setup_target_flags %}
export CFLAGS="${CFLAGS} -UNDEBUG"
{% endblock %}
