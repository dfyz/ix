{% extends '//die/hub.sh' %}

{% block lib_deps %}
{% if linux %}
lib/bumpalloc
lib/compiler_rt/builtins
lib/musl/naked
{% else %}
lib/c
{% endif %}
{% endblock %}
