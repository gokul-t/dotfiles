# Validate Changes Rules

## Before Any Commit

Always run these validations:

```sh
# 1. Ansible playbook syntax
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check

# 2. All YAML files
python3 - <<'PY'
from pathlib import Path
import yaml
for path in sorted(Path('ansible').rglob('*.yml')):
    yaml.safe_load(open(path))
    print(f'✓ Valid: {path}')
PY

# 3. Stow package test
stow <package-name>
```

## When to Validate

- After editing any `ansible/` file
- After adding/changing package directories
- Before any commit or PR
