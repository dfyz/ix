{% extends '//lib/compiler_rt/sanitize/t/ix.sh' %}

{% block cmake_flags %}
{{super()}}
COMPILER_RT_SANITIZERS_TO_BUILD=asan
{% endblock %}
