{% extends '//die/c/ix.sh' %}

{#
When building LLVM components with sanitizer support, the sanitizer runtime contains references
to some of the function defined by the components. Normally, this is not a problem, since we
will resolve this references down the line when linking the final binary. However, CMake refuses
to build anything if it can't succesfully link a simple binary at this point, so we have to trick
it into believing it can by providing fake definitions for the unresolved references.
#}

{% block unpack %}
: nothing to unpack
{% endblock %}

{% block build %}
>sanitizer_shims.c
# The signatures are all wrong, and some of these are not even functions.
# We only care that a symbol with a given name is defined somehow.
for sym in \
  _Unwind_GetIP _Unwind_Backtrace \
  __real___cxa_throw __real___cxa_rethrow_primary_exception __real__Unwind_RaiseException \
  __dynamic_cast \
  _ZTIN10__cxxabiv121__vmi_class_type_infoE \
  _ZTIN10__cxxabiv120__si_class_type_infoE \
  _ZTIN10__cxxabiv117__class_type_infoE \
  _ZTISt9type_info
do
  echo "
  void ${sym}() {}
  " >>sanitizer_shims.c
done

cc -O2 -c sanitizer_shims.c
ar qs libsanitizer_shims.a sanitizer_shims.o
{% endblock %}

{% block install %}
mkdir ${out}/lib
cp libsanitizer_shims.a ${out}/lib/libsanitizer_shims.a
{% endblock %}
