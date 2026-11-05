# Dev Workflow Rules

## Repository Type
This is a **dotfiles repository**, not application code.

## Commands to Know
```sh
# Validate Ansible syntax
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check

# Validate all YAML files
python3 - <<'PY'
from pathlib import Path
import yaml
for path in sorted(Path('ansible').rglob('*.yml')):
    yaml.safe_load(open(path))
    print(f'✓ Valid: {path}')
PY

# Test stow link
stow <package-name>

# Re-run stow via Ansible
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow
```

## Key Files
- `ansible/site.yml` - main entry point
- `ansible/tasks/stow.yml` - linking logic
- `ansible/profiles/*.yml` - active packages
- Packaged directories (`nvim/`, `tmux/`, `zsh/`, `git/`, etc.)

## Before Making Changes
Check README.md and the relevant package directory. Use stow to test changes.

## Conventions
- One tool per top-level directory
- Files mirror $HOME layout
- Use existing Ansible tasks
- Prefer minimal, scoped edits
