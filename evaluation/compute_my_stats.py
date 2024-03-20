#!/usr/bin/env python3

import sys
import random
from common import extract_checks, extracted_checks_to_function_names, read_lines_to_set, compute_recall, extract_ground_truth_to_dict, extracted_checks_to_dict, compute_precision, print_time_line

if len(sys.argv) != 2:
    print(f'Usage: {sys.argv[0]} <program (e.g. openssl, zlib, ...)>')
    sys.exit(1)

program = sys.argv[1]
input_set = extract_checks(f'my-{program}-output')
input_dict = extracted_checks_to_dict(input_set)
input_function_names = extracted_checks_to_function_names(input_set)

recall = precision = None

try:
    reference_function_names = read_lines_to_set(f'{program}-recall-sample')
    #print(input_function_names, reference_function_names)
    recall = compute_recall(input_function_names, reference_function_names)
except Exception as e:
    print(e)
    
print('--------------------------')

try:
    precision_ground_truth = extract_ground_truth_to_dict(f'{program}-precision-ground-truth')
    random_functions_for_precision = read_lines_to_set(f'{program}-random-functions-for-precision-my-tool')
    #print(random_functions_for_precision, precision_ground_truth)
    precision = compute_precision(input_dict, precision_ground_truth)
except Exception as e:
    print(e)

print('--------------------------')

if recall is not None and precision is not None:
    f1_score = 2 * (precision * recall) / (precision + recall)
    print(f'F1 score: {f1_score:.2%}')

print_time_line(f'my-{program}-output')
