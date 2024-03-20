#!/usr/bin/env python3

import re


def extract_checks(filename):
    lines = []
    marked = False
    for line in open(filename):
        if line.startswith('Function error return intervals ('):
            marked = True
        elif line.startswith('time=') or line.startswith('Skip: ') or line.startswith('Potential bug'):
            marked = False
        elif marked:
            lines.append(line.strip())

    lines = set('\t'.join(lines[i:i+2]) for i in range(0, len(lines), 2))
    if '' in lines:
        lines.remove('')
    return lines

def extracted_checks_to_dict(checks):
    res = dict()
    for input_entry in checks:
        searched = re.search('^Function: ([a-zA-Z0-9_, \*\(\)]+) {return index \d+}\t(.+)$', input_entry)
        if not searched:
            continue
        function_name = searched.group(1)
        interval = searched.group(2)
        res[function_name] = interval
    return res

def extracted_checks_to_function_names(checks):
    result = extracted_checks_to_dict(checks)
    return set(result.keys())

def read_lines_to_set(filename):
    return set(line.rstrip() for line in open(filename))

def extract_eesi_lines_to_function_names(filename):
    res = set()
    for line in open(filename):
        function_name, _ = line.split(':')
        res.add(function_name)
    return res

def extract_ground_truth_to_dict(filename):
    res = dict()
    for line in open(filename):
        try:
            function_name, interval = line.rstrip().split('\t')
        except:
            continue
        res[function_name] = interval
    return res

def compute_recall(input_function_names, reference_function_names):
    difference = reference_function_names.difference(input_function_names)
    expected_count = len(reference_function_names)
    percentage_recall = (expected_count - len(difference)) / expected_count
    print('Expected, but not found functions:')
    for entry in difference:
        print(f'\t{entry}')
    print(f'Recall: {expected_count - len(difference)}/{expected_count} = {percentage_recall:.2%}')
    return percentage_recall

def compute_precision(input_dict, reference_dict):
    # Verify that everything in the reference occurs in the input
    input_keys = set(input_dict.keys())
    reference_keys = set(reference_dict.keys())
    if len(reference_keys.difference(input_keys)) > 0:
        print('WARNING: Everything in the reference should occur in the output!')

    # Actual computation
    nr_of_matches = 0
    for reference_function_name, reference_interval in reference_dict.items():
        input_interval = input_dict.get(reference_function_name)
        if not input_interval:
            print(f'\tNo input data for "{reference_function_name}"')
            continue
        is_match = input_interval == reference_interval
        if is_match:
            nr_of_matches += 1
        else:
            print(f'\tNot matching for "{reference_function_name}": got {input_interval}, expected {reference_interval}')

    percentage_precision = nr_of_matches / len(reference_dict)
    print(f'Precision: {nr_of_matches}/{len(reference_dict)} = {percentage_precision:.2%}')
    return percentage_precision

def print_time_line(filename):
    for line in open(filename):
        if line.startswith('time='):
            print(line)
            return
    print('???')
