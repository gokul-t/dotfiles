# Skill: Validate Changes

## Purpose

This skill helps you validate changes to the dotfiles repository before committing. It provides commands to test your changes safely.

## Usage

After making changes to any package:

1. **Validate YAML syntax**:
   ```sh
   python3 - <<'PY'
   from pathlib import Path
   import yaml
   for path in sorted(Path('ansible').rglob('*.yml')):
       yaml.safe_load(open(path))
       print(f'✓ Valid: {path}')
   PY
   ```

2. **Test package linking with stow**:
   ```sh
   stow <package-name>
   ```

3. **Full validation via Ansible**:
   ```sh
   ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow --check
   ```

## Pre-Commit Checklist

- [ ] YAML files are valid
- [ ] Stow package structure is correct
- [ ] No new app source code in packages
- [ ] Change is scoped to single package
