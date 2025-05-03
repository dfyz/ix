{% extends '//die/env.sh' %}

{% block env %}
export OPTFLAGS="-fsanitize=memory -fno-omit-frame-pointer ${OPTFLAGS}"
{% endblock %}
