#!/bin/sh -e

HOST=$1

./configure \
  --host=$1 \
  --disable-debug-runtime \
  --disable-debugger \
  --disable-instrumented-runtime \
  --disable-ocamldoc \
  --disable-ocamltest \
  --disable-stdlib-manpages \
  --disable-shared \
  --with-pic \
  --without-odoc

make runtime/primitives runtime/sak SAK_CC=cc SAK_LINK='cc -o $(1) $(2)'

cp `which ocamlrun` runtime/ocamlrun
cp -f Makefile.cross Makefile.config
cp -f s-ios.h runtime/caml/s.h
cp -f m-ios.h runtime/caml/m.h
sed -i.bak \
  's|^runtime_ASM_OBJECTS = .*|runtime_ASM_OBJECTS = $(addprefix runtime/,arm64.o)|' \
  Makefile.build_config
CC_CONFIG=$(sed -n 's/^CC=//p' Makefile.cross)
ASM_CONFIG=$(sed -n 's/^ASM=//p' Makefile.cross | sed "s|\${CC}|${CC_CONFIG}|g")
PACKLD_CONFIG=$(sed -n 's/^PACKLD=//p' Makefile.cross | sed 's/$(EMPTY)//g')
CFLAGS_CONFIG=$(sed -n 's/^CFLAGS?=//p' Makefile.cross)
OCAMLC_CFLAGS_CONFIG="-O2 -fno-strict-aliasing -fwrapv -pthread ${CFLAGS_CONFIG}"
STANDARD_LIBRARY_CONFIG="${OPAM_SWITCH_PREFIX}/ios-sysroot/lib/ocaml"
export ASM_CONFIG PACKLD_CONFIG OCAMLC_CFLAGS_CONFIG STANDARD_LIBRARY_CONFIG
perl -0pi -e '
  s/^let standard_library_default = .*/let standard_library_default = {|$ENV{STANDARD_LIBRARY_CONFIG}|}/m;
  s/^let ocamlc_cflags = .*/let ocamlc_cflags = {|$ENV{OCAMLC_CFLAGS_CONFIG}|}/m;
  s/^let ocamlopt_cflags = .*/let ocamlopt_cflags = {|$ENV{OCAMLC_CFLAGS_CONFIG}|}/m;
  s/^let native_pack_linker = .*/let native_pack_linker = {|$ENV{PACKLD_CONFIG}|}/m;
  s/^let native_compiler = .*/let native_compiler = true/m;
  s/^let architecture = .*/let architecture = {|arm64|}/m;
  s/^let system = .*/let system = {|macosx|}/m;
  s/^let asm = .*/let asm = {|$ENV{ASM_CONFIG}|}/m;
  s/^let asm_cfi_supported = .*/let asm_cfi_supported = true/m;
' utils/config.generated.ml
rm -f utils/config.ml utils/config_main.ml

make coldstart coreall ocaml otherlibraries \
  runtimeopt ocamlopt libraryopt otherlibrariesopt \
  compilerlibs/ocamlcommon.cmxa compilerlibs/ocamlbytecomp.cmxa \
  compilerlibs/ocamloptcomp.cmxa driver/main.cmx driver/optmain.cmx \
  runtime_PROGRAMS= \
  OCAMLRUN=ocamlrun \
  NEW_OCAMLRUN=ocamlrun
