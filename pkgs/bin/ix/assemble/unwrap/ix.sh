{% extends '//bin/assemble/ix.sh' %}

{% block build_flags %}
{{super()}}
{% if not riscv64 %}
compress
{% endif %}
{% endblock %}
