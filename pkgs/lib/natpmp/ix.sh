{% extends '//die/c/make.sh' %}

{% block pkg_name %}
libnatpmp
{% endblock %}

{% block version %}
20150609
{% endblock %}

{% block fetch %}
https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libnatpmp/{{self.version().strip()}}-7.1build2/libnatpmp_{{self.version().strip()}}.orig.tar.gz
sha:e1aa9c4c4219bc06943d6b2130f664daee213fb262fcb94dd355815b8f4536b0
{% endblock %}

{% block lib_deps %}
lib/c
{% endblock %}

{% block build_flags %}
wrap_cc
{% endblock %}

{% block make_flags %}
CC=clang
INSTALLPREFIX=${out}
{% endblock %}

{% block build %}
{{super()}}
>natpmpc-shared
{% endblock %}
