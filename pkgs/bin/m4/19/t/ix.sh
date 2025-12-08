{% extends '//die/c/autohell.sh' %}

{% block pkg_name %}
m4
{% endblock %}

{% block version %}
1.4.20
{% endblock %}

{% block fetch %}
https://ftp.gnu.org/gnu/m4/m4-{{self.version().strip()}}.tar.xz
e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b
{% endblock %}

{% block bld_libs %}
lib/c
lib/intl
lib/sigsegv
{% endblock %}

{% block std_box %}
{{super()}}
bld/help2man
{% endblock %}

{% block configure %}
{{ super() }}
{#
For cross-compiling, avoid the fallback implemented in
https://gitweb.git.savannah.gnu.org/gitweb/?p=gnulib.git;a=commit;h=f7576a33332e4bc63fc0b15801a82abe865304ca
This fallback doesn't work for musl because
PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP is a glibc-ism.
#}
{# FIXME: this should eventually go to lib/musl/env #}
export gl_cv_func_pthread_rwlock_good_waitqueue=yes
{% endblock %}

{% block configure_flags %}
--disable-c++
{% endblock %}
