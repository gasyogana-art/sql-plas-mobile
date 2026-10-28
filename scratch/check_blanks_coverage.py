import json
import re

with open('assets/data/problems.json', 'r', encoding='utf-8') as f:
    problems = json.load(f)

unaccounted_blanks = []
duplicate_blanks = []

for p in problems:
    p_id = p['id']
    inputs = {inp['index']: inp for inp in p.get('inputs', [])}
    code_template = p.get('code_template', '')
    questions = p.get('questions', [])
    
    code_blank_placeholders = re.findall(r'\[\[BLANK_([^\]]+)\]\]', code_template)
    
    # Map placeholders to input indices
    code_blank_indices = set()
    for ph in code_blank_placeholders:
        for inp in inputs.values():
            if inp['placeholder'] == ph:
                code_blank_indices.add(inp['index'])
                
    question_blank_indices = {q['blank_index'] for q in questions if 'blank_index' in q}
    
    for b_idx in inputs.keys():
        in_code = b_idx in code_blank_indices
        in_q = b_idx in question_blank_indices
        
        if not in_code and not in_q:
            unaccounted_blanks.append((p_id, b_idx, inputs[b_idx]['placeholder']))
        elif in_code and in_q:
            duplicate_blanks.append((p_id, b_idx, inputs[b_idx]['placeholder']))

print("=== Coverage Check ===")
print(f"Total problems: {len(problems)}")
print(f"Unaccounted blanks (neither in code nor in questions): {len(unaccounted_blanks)}")
if unaccounted_blanks:
    print(unaccounted_blanks)
else:
    print("ALL 132 blanks are properly placed in code or questions!")

print(f"Blanks appearing in BOTH code and questions: {len(duplicate_blanks)}")
if duplicate_blanks:
    print(duplicate_blanks)
