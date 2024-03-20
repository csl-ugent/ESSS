#!/bin/bash
BC_FILES_BASE_DIR=~/APIMU4C/APIMU4C/httpd-2.4.37_patched/httpd-2.4.37/
./run-my-wrapper.sh "$BC_FILES_BASE_DIR" "/home/evaluation/build-musl-1.2.3/musl/prefix/lib/libc.so.bc" "" "$1"
