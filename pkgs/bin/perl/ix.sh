{% extends '//bin/perl/host/ix.sh' %}

{% block fetch %}
{{super()}}
https://github.com/arsv/perl-cross/releases/download/1.6.4/perl-cross-1.6.4.tar.gz
b6202173b0a8a43fb312867d85a8cd33527f3f234b1b6e591cdaa9895c9920c7
{% endblock %}

{% block unpack %}
extract0 ${src}/perl*
cd perl*
extract1 ${src}/perl-cross*
{% endblock %}

{% block host_libs %}
lib/c
{% endblock %}

{% block patch %}
{{super()}}
rm Configure
cat > Configure <<'EOF'
#!/bin/sh

n=$#

for arg in "$@"
do
    case "$arg" in
        # The configure from perl-cross doesn't know about `-s`.
        "-des") arg="" ;;
        # Apparently this option needs to be undefined, not set to `false`.
        "-Dusedl=false") arg="-Uusedl" ;;
    esac
    set -- "$@" "$arg"
done

shift "$n"

{% if not native %}
set -- "$@" --target={{target.gnu.three}}
{% endif %}

exec ./configure "$@"
EOF

{#
`#line` directives are necessary for `ext/Errno/Errno_pm.PL` to detect
the errno file paths when parsing the `cpp` output, but the configure
script for perl-cross explicitly removes these directives with `-P`.
For non-IX builds, `ext/Errno/Errno_pm.PL` apparently keeps working
by falling back to sysroot searches, but for IX parsing the `cpp`
output is the only viable option.
#}
sed -i 's/define cpp "$cc -E -P"/define cpp "$cc -E"/' cnf/configure_tool.sh

{#
The configure script from perl-cross tries to determine endianness
by assuming the section name for symbol `foo` is exactly `.data`.
However, for IX, the section name includes the symbol name
(i.e., it's `data.foo` instead of just `.data`).
#}
sed -i 's/-j \.\(sdata\|data\)/-j .\1.foo/g' cnf/configure_type_sel.sh
{% endblock %}

{% block configure %}
export OBJDUMP=llvm-objdump
export READELF=llvm-readelf

export HOSTOBJDUMP=${OBJDUMP}
export HOSTREADELF=${READELF}

export HOSTCC=${HOST_CC}
{{super()}}
{% endblock %}

{#
The configure checks are ran with this define, so we have to define
it when compiling, too (both for the host and for the target).
#}
{% block cpp_defines %}
_GNU_SOURCE=1
{% endblock %}

{% block setup_host_flags %}
export CFLAGS="-D_GNU_SOURCE=1 ${CFLAGS}"
{% endblock %}