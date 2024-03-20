#!/usr/bin/env python3

import sys
import random

# ./random_sampling_of_lines.py <gotten output (file)> <#samples>
assert len(sys.argv) == 3

def extract_checks(filename):
    lines = []
    for line in open(filename):
        if ': ' in line:
            lines.append(line)

    lines = set(lines)
    if '' in lines:
        lines.remove('')
    return lines

input_set = extract_checks(sys.argv[1])
nr_samples = int(sys.argv[2])
if nr_samples > len(input_set):
    print(f'You requested {nr_samples} samples, but I only have {len(input_set)} entries')
    sys.exit(1)
random_samples = random.sample(list(input_set), nr_samples)
print(''.join(random_samples), end='')
