#!/bin/bash

set -ex

export LLVM_COMPILER=clang
export LLVM_COMPILER_PATH="$(realpath ../llvm/llvm-project/prefix/bin)"

wllvm -c example.c
extract-bc ./example.o

../analyzer/build/lib/kanalyzer ./example.o.bc
