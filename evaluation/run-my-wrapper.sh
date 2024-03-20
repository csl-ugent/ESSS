#!/bin/bash

if [ $# -ne 3 ] && [ $# -ne 4 ] && [ $# -ne 5 ]; then
    echo "Usage: $0 <directory of project> <additional files> [function filters, comma separated] [missing check threshold]" >&2
    exit 1
fi

ANALYZER=$(realpath ../analyzer/build/lib/kanalyzer)

GLOBIGNORE=.:..

pushd "$1"
# NOTE: analyzing the whole combined.bc file instead of separate modules should give the same result,
#       but the advantage of using separate modules is that we can process them in parallel
# NOTE: for sampling: --print-random-non-void-function-samples 250
missing_ct="$4"
if [ "$missing_ct" == "" ]; then
    missing_ct="0.725"
fi
/usr/bin/time --format='time=%E memory=%M' -- "$ANALYZER" -c 1 --missing-ct="$missing_ct" --function-test-cases-to-analyzer="$3" --verbose-level=0 "$2" tmp/* tmp/.*
popd
