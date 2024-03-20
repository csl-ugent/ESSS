#!/usr/bin/env python3

import sys
import random
from common import extract_checks

# ./random_sampling_of_my_specs.py <gotten output (file)> <#samples>
assert len(sys.argv) == 3

input_set = extract_checks(sys.argv[1])
nr_samples = int(sys.argv[2])
if nr_samples > len(input_set):
    print(f'You requested {nr_samples} samples, but I only have {len(input_set)} entries')
    sys.exit(1)
random_samples = random.sample(list(input_set), nr_samples)
print('\n'.join(random_samples))
