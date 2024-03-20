#!/bin/bash
BC_FILES_BASE_DIR=~/APIMU4C/APIMU4C/curl-curl-7_63_0_patched/curl-curl-7_63_0/
./run-my-wrapper.sh "$BC_FILES_BASE_DIR" "/home/evaluation/build-musl-1.2.3/musl/prefix/lib/libc.so.bc" "" "$1"
