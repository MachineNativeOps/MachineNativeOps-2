#!/usr/bin/env python3
"""Fix indentation in validate-root-specs.py"""

with open('controlplane/baseline/validation/validate-root-specs.py', 'r') as f:
    lines = f.readlines()

# Fix line 447 and subsequent lines that are part of the new methods
fixed_lines = []
in_new_method = False
for i, line in enumerate(lines, 1):
    # Check if this is one of the new method definitions (wrong indentation)
    if i >= 447 and line.strip().startswith('def validate_'):
        # This should be a class method with 4 spaces
        fixed_lines.append('    ' + line.lstrip())
        in_new_method = True
    elif in_new_method and line.strip() and not line.startswith('    '):
        # Fix indentation for method body
        # Count leading spaces
        leading_spaces = len(line) - len(line.lstrip())
        if leading_spaces < 8:  # Should be at least 8 for method body
            fixed_lines.append('    ' + line)
        else:
            fixed_lines.append(line)
    else:
        fixed_lines.append(line)
        if line.strip().startswith('def main():'):
            in_new_method = False

with open('controlplane/baseline/validation/validate-root-specs.py', 'w') as f:
    f.writelines(fixed_lines)

print("Fixed indentation")