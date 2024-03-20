#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [program]" >&2
    exit 1
fi

"./run-my-$1.sh" &> "my-$1-output"
./compute_my_stats.py "$1"
./check_found_bugs.py "$1"
