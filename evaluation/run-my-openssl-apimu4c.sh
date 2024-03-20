#!/bin/bash
BC_FILES_BASE_DIR=~/APIMU4C/APIMU4C/openssl-1-1-pre8_patched/openssl-1-1-pre8_patched/
./run-my-wrapper.sh "$BC_FILES_BASE_DIR" "/home/evaluation/build-musl-1.2.3/musl/prefix/lib/libc.so.bc" "" "$1"
