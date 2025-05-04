{% extends '//die/env.sh' %}

{#
When building LLVM components with sanitizer support, the sanitizer runtime contains references
to some of the function defined by the components. Normally, this is not a problem, since we
will resolve this references down the line when linking the final binary. However, CMake refuses
to build anything if it can't succesfully link a simple binary at this point, so we have to trick
it into believing it can by ignoring all unresolved symbol errors.
#}

{% block env %}
export LDFLAGS="-Wl,--unresolved-symbols=ignore-all ${LDFLAGS}"
{% endblock %}
