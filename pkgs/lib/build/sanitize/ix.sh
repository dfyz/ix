{% extends '//die/hub.sh' %}

{% block lib_deps %}
{% if sanitize %}
lib/build/sanitize/{{sanitize}}
lib/compiler_rt/sanitize/{{sanitize}}(sanitize=)
{% endif %}
{% endblock %}
