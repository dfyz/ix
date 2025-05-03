{% extends '//die/env.sh' %}

{% block env %}
export CFLAGS="-fsanitize=memory -fno-omit-frame-pointer ${CFLAGS}"
{% endblock %}
