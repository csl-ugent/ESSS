#!/usr/bin/env python3

import sys

# ./check_output.py <gotten output (file)> <expected output (file)>
assert len(sys.argv) == 3

def extract_checks(filename):
    lines = []
    marked = False
    for line in open(filename):
        if line.startswith('Safety checks found using similarities:'):
            marked = True
        elif line.startswith('['):
            marked = False
        elif marked:
            lines.append(line.strip())

    lines = set('\n'.join(lines[i:i+2]) for i in range(0, len(lines), 2))
    if '' in lines:
        lines.remove('')
    return lines

input_set = extract_checks(sys.argv[1])
expected_set = extract_checks(sys.argv[2])
if input_set != expected_set:
    print('NOT MATCHING:', sys.argv[2])
    print()
    diff = input_set.difference(expected_set)
    if diff:
        #print(diff)
        print('Actual output has but missing in expected output:')
        print('\n'.join(d.replace('\n', '\t') for d in diff))
    print()
    diff = expected_set.difference(input_set)
    if diff:
        print('Expected output has but missing in actual output:')
        print('\n'.join(d.replace('\n', '\t') for d in diff))
    sys.exit(1)
