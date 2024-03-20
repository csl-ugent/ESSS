#!/usr/bin/env python3

import sys
import random
from common import extract_eesi_lines_to_function_names, compute_recall, read_lines_to_set

# ./random_sampling_of_my_specs.py <eesi output (file)> <eesi output precision (file)> <recall reference (file)>
assert len(sys.argv) == 4

input_function_names = extract_eesi_lines_to_function_names(sys.argv[1])
reference_function_names = read_lines_to_set(sys.argv[3])
#print(input_function_names, reference_function_names)

recall = compute_recall(input_function_names, reference_function_names)

# Precision
precision_T = 0
precision_F = 0
with open(sys.argv[2]) as f:
    for line in f:
        if line[0] == 'T':
            precision_T += 1
        else:
            precision_F += 1

percentage_precision = precision_T / (precision_T + precision_F)
print(f'Precision: {precision_T}/{precision_T + precision_F} = {percentage_precision:.2%}')

f1_score = 2 * (percentage_precision * recall) / (percentage_precision + recall)
print(f'F1 score: {f1_score:.2%}')
