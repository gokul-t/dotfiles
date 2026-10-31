# Copilot Instructions for this dotfiles repository

## Repository purpose

This repository is a GNU Stow-based dotfiles collection for a developer workstation. It does not contain a normal application service or library; it contains per-tool configuration packages that are linked into `$HOME` and orchestrated by Ansible.

Treat changes as system configuration work:
- Top-level directories are individual Stow packages (for example `zsh`, `tmux`, `nvim`, `git`, `alacritty`, `lazygit`, `starship`, `sesh`, `code`, `claude`).
- Each package usually contains the config files and directories for one application.
- `ansible/site.yml` is the orchestration entry point for provisioning and setup.

## Validation and setup commands

There is no application build/test suite in this repo. The actual validation path is configuration and provisioning validation:

```sh
# Validate the Ansible playbook syntax
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check

# Validate YAML files under ansible/
python3 - <<'PY'
from pathlib import Path
import yaml

for path in sorted(Path('ansible').rglob('*.yml')):
    with path.open() as stream:
        yaml.safe_load(stream)
    print(f'Valid YAML: {path}')
PY

# Apply the workstation setup locally
ansible-playbook -i ansible/inventory.ini ansible/site.yml

# Link one package into the home directory manually
stow <package-name>

# Link the default workstation packages via Ansible
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow

# Check package selection against disposable targets
bash ansible/containers/test-stow.sh
```

When changing one config package, prefer validating the package or the Ansible flow rather than adding project-level unit tests.

## High-level architecture

The repository follows a simple pattern:

- `ansible/` contains the provisioning logic. The main playbook checks the OS, installs Fedora, Ubuntu, or macOS packages, links dotfiles with GNU Stow, and installs user tools such as Oh My Zsh plugins, TPM, Lazy-Idea, and mise.
- `ansible/tasks/stow.yml` links the packages listed in the active profile (`ansible/profiles/*.yml`, `dotfiles_profile_stow_packages`); add new Stow packages there. `ansible/packages/` holds the OS package manifests.
- `ansible/tasks/user-tools.yml` installs external ecosystem tooling such as Oh My Zsh, tmux plugin manager, Lazy-Idea, and `mise`.
- The top-level package directories define the actual user-facing configuration. Examples:
  - `zsh` / `bash` / `tmux` for shell and terminal behavior
  - `nvim` for editor config
  - `git` and `code` for Git and editor settings
  - `alacritty`, `ghostty`, and `starship` for terminal appearance
  - `dev`-adjacent config packages such as `mise`, `npm`, `yazi`, `lazygit`, and `claude`

The repo is intentionally organized around machine setup, not app source code.

## Key conventions

- Keep each tool’s config under its own top-level directory; do not scatter related files across the repo root.
- Prefer Stow-style package names that match the target app or tool (`nvim`, `git`, `zsh`, etc.).
- Preserve the home-directory layout expected by the tool, not the repo layout. The top-level directories are the package roots; the files inside them are arranged to match the target dotfiles paths.
- Use the existing Ansible entry points for OS-specific installation and package setup instead of introducing ad hoc install scripts.
- Respect the repository’s portability: the playbook supports Fedora, Ubuntu (including WSL), and macOS, with OS-specific tasks in `ansible/tasks/`.
- Keep user-specific or machine-specific overrides outside the Git-tracked repo when appropriate; the repo already relies on local config paths like `git/.identity.conf`.
- When editing a configuration package, update only that package and validate with the relevant Stow or Ansible flow.

## Files worth checking before changing behavior

- `README.md` for installation and platform expectations
- `ansible/site.yml` for the overall provisioning flow
- `ansible/tasks/stow.yml` for the Stow behavior
- `ansible/tasks/user-tools.yml` for shell/editor tooling setup
- Any package directory relevant to the tool being changed (for example `tmux/`, `nvim/`, `zsh/`, `git/`)

## When making changes

- Prefer minimal, scoped edits to one package at a time.
- Avoid adding conventional app code or build artifacts; this repo is config-first.
- If you need to change provisioning behavior, update the Ansible tasks and keep the change idempotent.
- If you introduce new tool packages, add them in the same Stow package pattern so the repository remains predictable.
