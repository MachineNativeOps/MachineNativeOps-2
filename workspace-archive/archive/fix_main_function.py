#!/usr/bin/env python3
"""Fix main function indentation"""

with open('controlplane/baseline/validation/validate-root-specs.py', 'r') as f:
    content = f.read()

# Find and fix the main function
lines = content.split('\n')
fixed_lines = []
in_main = False

for i, line in enumerate(lines):
    # Check if this is the main function definition
    if 'def main():' in line and not line.strip().startswith('#'):
        # This should be at module level (no indentation)
        fixed_lines.append('def main():')
        in_main = True
    elif in_main and line.strip().startswith('"""'):
        # Docstring should have 4 spaces
        fixed_lines.append('    """Main entry point"""')
    elif in_main and line.strip() and not line.startswith('def ') and not line.startswith('if __name__'):
        # Main function body should have 4 spaces
        stripped = line.lstrip()
        if stripped:
            fixed_lines.append('    ' + stripped)
        else:
            fixed_lines.append(line)
    elif 'if __name__' in line:
        in_main = False
        fixed_lines.append(line)
    else:
        fixed_lines.append(line)

with open('controlplane/baseline/validation/validate-root-specs.py', 'w') as f:
    f.write('\n'.join(fixed_lines))

print("Fixed main function indentation")