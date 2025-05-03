#!/usr/bin/env sh

llvm-nm -AgjU ${1} | cut -d ' ' -f 2 | sort -u > defined_syms
cat defined_syms $(dirname ${0})/intercepted_symbols.txt | sort | uniq -d | sed 's/.*/& __real_&/' > redefs
llvm-objcopy --redefine-syms=redefs ${1}
