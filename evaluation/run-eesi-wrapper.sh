#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <bc filename> <specs filename suffix>" >&2
    exit 1
fi

OPT="$(realpath ../llvm/llvm-project/prefix/bin/opt)"
EESI_DIR=~/tools/eesi
BC_FILES_BASE_DIR=$(dirname $1)/
BC_FILES_BASE_FILE=$(basename $1)

GLOBIGNORE=.:..

pushd $BC_FILES_BASE_DIR
$OPT -reg2mem "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE" -o "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE"-reg2mem.bc
#opt -reg2mem "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE" -o "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE"-reg2mem.bc
/usr/bin/time --format='time=%E memory=%M' -- $EESI_DIR/build/eesi --bitcode "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE"-reg2mem.bc --command specs --inputspecs $EESI_DIR/config/input-specs-$2.txt --erroronly $EESI_DIR/config/error-only-$2.txt
#gdb --args $EESI_DIR/build/eesi --bitcode "$BC_FILES_BASE_DIR""$BC_FILES_BASE_FILE"-reg2mem.bc --command specs --inputspecs $EESI_DIR/config/input-specs-$2.txt --erroronly $EESI_DIR/config/error-only-$2.txt
popd
