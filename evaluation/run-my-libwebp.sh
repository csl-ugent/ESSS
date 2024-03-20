#!/bin/bash
BC_FILES_BASE_DIR=~/benchmarks/libwebp/
./run-my-wrapper.sh "$BC_FILES_BASE_DIR" "/home/evaluation/build-musl-1.2.3/musl/prefix/lib/libc.so.bc" "" "$1"
