{% extends '//die/gen.sh' %}

{% block bld_tool %}
bld/genpc
{% endblock %}

{% block install %}
genpc {{pkg_name}} {{pkg_ver}} << EOF
{{pkg_extra}}
EOF
{% endblock %}
