#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [program]" >&2
    exit 1
fi

for threshold in $(seq 0.725 0.01 0.995); do
    "./run-my-$1.sh" $threshold &> "my-$1-output"
    #./compute_my_stats.py "$1"
    echo "At threshold: $threshold"
    ./check_found_bugs.py "$1" | grep -E 'FPR:|M total '
    echo '----------------------------------'
done
wait
