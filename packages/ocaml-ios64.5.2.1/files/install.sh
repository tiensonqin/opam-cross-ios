#!/bin/sh -e

PREFIX="$1"

make install PROGRAMS=ocamlrun

HOST_OCAMLRUN=$(command -v ocamlrun)
export HOST_OCAMLRUN
for prog in ocaml ocamlc.byte ocamlcmt ocamlcp ocamldep.byte ocamllex.byte \
            ocamlmklib ocamlmktop ocamlobjinfo.byte ocamlopt.byte \
            ocamloptp ocamlprof ocamlyacc; do
  if [ -f "${PREFIX}/ios-sysroot/bin/${prog}" ]; then
    perl -0pi -e 's|\A#![^\n]*\n|#!$ENV{HOST_OCAMLRUN}\n|' \
      "${PREFIX}/ios-sysroot/bin/${prog}"
  fi
done

cp compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlcommon.a \
   compilerlibs/ocamlbytecomp.cmxa compilerlibs/ocamlbytecomp.a \
   compilerlibs/ocamloptcomp.cmxa compilerlibs/ocamloptcomp.a \
   driver/main.cmx driver/main.o \
   driver/optmain.cmx driver/optmain.o \
   "${PREFIX}/ios-sysroot/lib/ocaml/compiler-libs"

for pkg in bigarray bytes compiler-libs dynlink findlib graphics stdlib str threads unix; do
  if [ -f "${PREFIX}/lib/ocaml/${pkg}/META" ]; then
    mkdir -p "${PREFIX}/ios-sysroot/lib/${pkg}"
    cp "${PREFIX}/lib/ocaml/${pkg}/META" "${PREFIX}/ios-sysroot/lib/${pkg}/META"
  fi
done

mkdir -p "${PREFIX}/lib/findlib.conf.d"
cp ios.conf "${PREFIX}/lib/findlib.conf.d"
