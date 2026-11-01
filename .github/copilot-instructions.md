# Copilot Instructions for this dotfiles repository

## Repository purpose

This repo is a GNU Stow-based dotfiles collection for a developer workstation. It is not an application service or library; it is a set of configuration packages that are linked into `$HOME` and provisioned by Ansible.

The key concept is: top-level directories are individual Stow packages. Each package mirrors the target app/tool layout (`zsh`, `tmux`, `nvim`, `git`, `alacritty`, `lazygit`, etc.), and `ansible/site.yml` orchestrates installation and linking.

## Build, test, and lint commands

There is no application build/test suite in this repo. Validation is configuration-focused and should be kept narrow to the change.

```sh
# Validate the main Ansible playbook syntax
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check

# Validate all Ansible YAML files under ansible/
python3 - <<'PY'
from pathlib import Path
import yaml

for path in sorted(Path('ansible').rglob('*.yml')):
    with path.open() as stream:
        yaml.safe_load(stream)
    print(f'Valid YAML: {path}')
PY

# Link one package into the home directory manually
stow <package-name>

# Re-run the Stow step for the active profile via Ansible
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow

# Sanity-check selected packages against disposable targets
bash ansible/containers/test-stow.sh
```

When changing a single config package, prefer validating that package with `stow` or the relevant Ansible flow instead of inventing project-wide tests. If a change touches provisioning logic, validate the playbook syntax or the specific Ansible task path you edited.

## High-level architecture

- `ansible/site.yml` is the main provisioning entry point. It validates the selected profile and dispatches to OS-specific package installs, `stow`, and user-tool setup.
- `ansible/tasks/stow.yml` is the critical link step: it discovers top-level package directories, filters the selected packages from `ansible/profiles/*.yml`, and runs `stow --dir ... --target ... --stow` for each one.
- `ansible/profiles/*.yml` defines the package list for each profile. The default workstation profile contains the active tool set (for example `alacritty`, `bash`, `git`, `nvim`, `tmux`, `zsh`, `starship`, `yazi`, `claude`, etc.).
- `ansible/tasks/user-tools.yml` installs additional user-space tools such as Oh My Zsh, TPM, LazyVim/Idea plugins, and `mise`.
- `ansible/packages/` holds OS-specific package manifests; `ansible/containers/test-stow.sh` checks that package selection works with disposable targets.
- Top-level directories such as `nvim/`, `tmux/`, `zsh/`, `git/`, `code/`, and `ghostty/` are the actual config packages, not application source trees.

This repo is organized around machine setup and shell/editor ergonomics rather than conventional app code. The right mental model is “config package per tool” plus “Ansible orchestrates linking and setup.”

## Key conventions

- Keep each tool’s configuration under its own top-level directory; do not spread one tool’s files across the repo root.
- Preserve the target home-directory layout, not the repository layout. Files inside a package should match the actual config paths expected by the tool.
- Prefer Stow package names that match the target app or tool (`nvim`, `git`, `zsh`, `tmux`, `lazygit`, etc.).
- Use the existing Ansible tasks and profiles instead of adding ad hoc setup scripts. If a new tool needs to be linked, add it to the relevant profile and keep the package directory consistent.
- Respect portability: the playbook supports Fedora, Ubuntu/WSL, and macOS; OS-specific behavior lives in `ansible/tasks/` and package manifests. Do not write platform assumptions that bypass that flow.
- Keep machine-specific or user-specific overrides outside the tracked repo when appropriate; the project already uses patterns like `git/.identity.conf` for local config.
- Prefer minimal, scoped edits to a single package at a time and validate only the relevant Stow or Ansible path.

## Files worth checking before making a change

- `README.md` for repo purpose and supported setup paths
- `ansible/site.yml` for the main orchestration flow
- `ansible/tasks/stow.yml` for how packages are linked
- `ansible/profiles/*.yml` for active package lists
- `ansible/tasks/user-tools.yml` for shell/tooling setup
- The package directory relevant to the change (`tmux/`, `nvim/`, `zsh/`, `git/`, etc.)

## What to avoid

- Do not add conventional app source code or build artifacts to a config package.
- Do not invent new repo-wide test infrastructure when Stow/Ansible validation is the real validation path.
- Do not create ad hoc install scripts when the repo already has Ansible tasks and package manifests.

