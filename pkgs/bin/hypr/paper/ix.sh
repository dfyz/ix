{% extends '//bin/hypr/t/ix.sh' %}

{% block pkg_name %}
hyprpaper
{% endblock %}

{% block version %}
0.7.4
{% endblock %}

{% block fetch %}
https://github.com/hyprwm/hyprpaper/archive/refs/tags/v{{self.version().strip()}}.tar.gz
sha:a2375dae58d29293b942a60cd465771b2c3c85cfcac628ec4897f11e7008666f
{% endblock %}

{% block bld_libs %}
{{super()}}
lib/webp
lib/hypr/lang
lib/hypr/graphics
{% endblock %}

{% block bld_tool %}
{{super()}}
bin/hypr/wayland/scanner
{% endblock %}

{% block install %}
mkdir ${out}/bin
cp ${tmp}/obj/hyprpaper ${out}/bin/
{% endblock %}
