#!/usr/bin/env python3

import sys
from collections import defaultdict

# ./check_found_bugs.py <program>
assert len(sys.argv) == 2

program = sys.argv[1]

bug_map = dict()
expected_bugs_set_AorC = set()
expected_bugs_set_PT = set()
for line in open(f'{program}-bugs'):
    line = line.rstrip()
    if not line or line[0] == '#':
        continue
    try:
        category, *_, identifier = line.split('\t')
    except ValueError:
        print('Failed to parse: ', line)
    if identifier in bug_map:
        raise KeyError(f'Identifier "{identifier}" must not already be in the bug map')
    bug_map[identifier] = category
    if category == 'I_PT' or category == 'M_PT':
        expected_bugs_set_PT.add(identifier)
    elif category == 'I_A' or category == 'I_C' or category == 'M_A' or category == 'M_C':
        expected_bugs_set_AorC.add(identifier)

prefix_counters = defaultdict(int)
category_mapper = defaultdict(set)
uncategorised_total = list()

found_bugs_set = set()
for line in open(f'my-{program}-output'):
    prefixes = ('Potential bug, not all error values are checked for the following call: ', 'Potential bug, truncation of error values: ', 'Potential bug, signedness bug: ', 'Potential bug, missing check for the following call: ')
    bug_type_names = ('I', 'T', 'S', 'M')
    for (prefix, bug_type_name) in zip(prefixes, bug_type_names):
        if line.startswith(prefix):
            prefix_counters[prefix] += 1
            identifier = line[len(prefix):].rstrip()
            found_bugs_set.add(identifier)

            if identifier in bug_map:
                category_mapper[bug_map[identifier]].add(identifier)
            else:
                category_mapper[f'{bug_type_name}_UC'].add(identifier)
                uncategorised_total.append(identifier)

not_found_bugs_set_PT = expected_bugs_set_PT.difference(found_bugs_set)
not_found_bugs_set_AorC = expected_bugs_set_AorC.difference(found_bugs_set)

print('Not found PT:')
for bug in not_found_bugs_set_PT:
    print(bug)

print('Not found A/C:')
for bug in not_found_bugs_set_AorC:
    print(bug)

print()
for k, v in prefix_counters.items():
    print(f'{k}{v}')

print()
print('Categories:')
total = sum(len(items) for items in category_mapper.values())
for k, v in category_mapper.items():
    print(f'{k}\t{len(v)}\t{len(v) / total * 100:.2f}%')

if True:
    for category in ('I_FNE', 'I_W', 'I_L', 'M_FNE', 'M_W', 'M_L'):
        print(f'\n{category}:')
        print('\n'.join(category_mapper[category]))

    if uncategorised_total:
        print('\nUncategorised:')
        print('\n'.join(uncategorised_total))

    W = len(category_mapper['I_W']) + len(category_mapper['M_W'])
    false_positives_count_incorrect = len(category_mapper['I_W']) + len(category_mapper['I_L']) + len(category_mapper['I_FPS']) + len(category_mapper['I_FNE']) + len(category_mapper['I_PF'])
    false_positives_count_missing = len(category_mapper['M_W']) + len(category_mapper['M_L']) + len(category_mapper['M_FPS']) + len(category_mapper['M_FNE']) + len(category_mapper['M_PF'])
    false_positives_count_total = false_positives_count_incorrect + false_positives_count_missing
    true_positives_count_incorrect = len(category_mapper['I_A']) + len(category_mapper['I_C']) + len(category_mapper['I_PT'])
    true_positives_count_missing = len(category_mapper['M_A']) + len(category_mapper['M_C']) + len(category_mapper['M_PT'])
    true_positives_count = true_positives_count_incorrect + true_positives_count_missing

    try:
        print(f'\nIncorrect FPR: {false_positives_count_incorrect / (true_positives_count_incorrect + false_positives_count_incorrect) * 100:.2f}%')
    except:
        pass
    try:
        print(f'Missing FPR: {false_positives_count_missing / (true_positives_count_missing + false_positives_count_missing) * 100:.2f}%')
    except:
        pass
    try:
        print(f'Total FPR: {false_positives_count_total / (true_positives_count + false_positives_count_total) * 100:.2f}%')
        print(f'Total FPR without W: {(false_positives_count_total - W) / (true_positives_count + false_positives_count_total - W) * 100:.2f}%')
    except:
        pass
    print(f'\nM total (absolute): {false_positives_count_missing + true_positives_count_missing + len(category_mapper["M_UC"])}')
    print(f'I total (absolute): {false_positives_count_incorrect + true_positives_count_incorrect + len(category_mapper["I_UC"])}')
    print(f'\nM total (absolute, no UC): {false_positives_count_missing + true_positives_count_missing}')
    print(f'I total (absolute, no UC): {false_positives_count_incorrect + true_positives_count_incorrect}')

    TARGET = 0.15
    # (fps - x) / (tps + fps - x) <= TARGET
    #   <=> fps - x = TARGET * (tps + fps - x)
    #   <=> fps - x = TARGET * (tps + fps) - TARGET * x
    #   <=> TARGET * x - x = TARGET * (tps + fps) - fps
    #   <=> x * (TARGET - 1) = TARGET * (tps + fps) - fps
    #   <=> x = (TARGET * (tps + fps) - fps) / (TARGET - 1)
    decrease_needed = (TARGET * (true_positives_count + false_positives_count_total) - false_positives_count_total) / (TARGET - 1)
    if decrease_needed > 0:
        print(f'Would need a decrease of {decrease_needed:.2f} false positives to reach a total FPR of {TARGET * 100:.2f}% (W was included in this calculation)')
