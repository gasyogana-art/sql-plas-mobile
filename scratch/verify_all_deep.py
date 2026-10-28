import json
import hashlib
import os

def sha256(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest().lower()

with open('assets/data/problems.json', 'r', encoding='utf-8') as f:
    problems = json.load(f)

errors = []
warnings = []

print(f"Total problems: {len(problems)}")

total_blanks = 0
correct_answers_found = 0

for p_idx, p in enumerate(problems):
    stmt = p['statement']
    p_id = p['id']
    name = p['name']
    
    # Check images
    for img_path in p.get('images', []):
        full_path = os.path.normpath(img_path)
        if not os.path.exists(full_path):
            errors.append(f"Problem #{p_id} ('{name}'): Image file missing at '{full_path}'")

    inputs = p.get('inputs', [])
    total_blanks += len(inputs)
    
    # Check blank inputs
    for inp in inputs:
        idx = inp['index']
        expected_hash = (inp.get('ans_hash') or inp.get('ansHash')).lower()
        options = inp.get('options', [])
        
        if not options:
            errors.append(f"Problem #{p_id} Blank {idx}: No options defined!")
            continue
            
        # Check if options have duplicates
        if len(options) != len(set(options)):
            warnings.append(f"Problem #{p_id} Blank {idx}: Options contain duplicates: {options}")
            
        # Find which option matches the hash
        match_count = 0
        matched_opt = None
        for opt in options:
            test_val = f"{opt}{stmt}{idx}"
            if sha256(test_val) == expected_hash:
                match_count += 1
                matched_opt = opt
                
        if match_count == 0:
            errors.append(f"Problem #{p_id} Blank {idx}: None of the options {options} match expected hash {expected_hash}!")
        elif match_count > 1:
            warnings.append(f"Problem #{p_id} Blank {idx}: Multiple options match hash! ({match_count} matches)")
        else:
            correct_answers_found += 1

    # Check questions mapping
    for q in p.get('questions', []):
        b_idx = q.get('blank_index') or q.get('blankIndex')
        # Ensure corresponding blank input exists
        matching_inp = next((inp for inp in inputs if inp['index'] == b_idx), None)
        if not matching_inp:
            errors.append(f"Problem #{p_id} Question '{q['text']}': blankIndex {b_idx} does not match any input!")
        else:
            # Check question options match input options
            q_options = q.get('options', [])
            inp_options = matching_inp.get('options', [])
            if q_options != inp_options:
                errors.append(f"Problem #{p_id} Question blankIndex {b_idx}: Question options {q_options} != Input options {inp_options}")

print(f"Total Blanks checked: {total_blanks}")
print(f"Correct answers matched in options: {correct_answers_found}/{total_blanks}")

if errors:
    print(f"\n[FAIL] Found {len(errors)} ERRORS:")
    for e in errors:
        print(f"  - {e}")
else:
    print("\n[PASS] ZERO errors found in dataset!")

if warnings:
    print(f"\n[WARN] Found {len(warnings)} WARNINGS:")
    for w in warnings:
        print(f"  - {w}")
else:
    print("[PASS] ZERO warnings in dataset!")
