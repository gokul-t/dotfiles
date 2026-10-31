# Automated Installation Guide

This guide describes how to set up your environment automatically using Ansible. This is the fastest way to get the full experience.

## 🚀 One-Command Setup

Run the following command from your terminal as a regular user:

```sh
curl -fsSL https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh | bash
```

### What this does:
1. **Bootstraps**: Installs Ansible and Git using the native package manager (`dnf` for Fedora, `apt` for Ubuntu/WSL, `brew` for macOS).
2. **Clones**: Pulls this repository into `~/.dotfiles`.
3. **Provisions**: Runs the Ansible playbook to:
   - Install all system packages listed in `ansible/packages/` (`dnf-packages.txt`, `ubuntu-packages.txt`, or `Brewfile`).
   - Install Flatpak/Snap applications.
   - Configure repositories for VS Code, Chrome, etc.
   - Use **GNU Stow** to symlink all configurations to your home directory.
   - Set up shell plugins and development tools (`mise`, etc.).
   - (Optional) Install **Toshy** for macOS-like keyboard shortcuts on Linux.

---

## 🏠 Homelab Server Setup

For minimal server installations (Ubuntu 24.04 or Debian 13), use the `server` profile. This installs only a lean set of essentials, skips GUI apps, and avoids changing your login shell.

```sh
curl -fsSL https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh | bash -s -- --profile server
```

### Server Profile Details:
- **Supported OS**: Ubuntu 24.04, Debian 13.
- **Installed**: Core utilities (`curl`, `git`, `vim`, `tmux`, `htop`, `ripgrep`, `jq`, etc.).
- **Stowed**: Only the `vim` configuration.
- **Preserved**: Existing login shell and Bash configuration. tmux uses its defaults (the workstation tmux config is not linked).
- **Not touched**: GUI apps, language runtimes, Zsh/plugins, Docker, SSH daemon, firewall, users, and services.
- **Prerequisites**: Run locally (e.g. over SSH) as a regular user with `sudo` and network access, not as root.
- **Existing files**: Stow never overwrites them; a conflicting `~/.vimrc` is left as is and reported. Pass `-e dotfiles_stow_strict=true` to fail instead.
- **Additive only**: Switching profiles does not remove previously installed workstation software or links.

---

## ⚙️ Customization

### Skipping Tools
If you want to skip specific tools (e.g., the `bin` manager), you can pass extra variables to the playbook:
```sh
# Example: Skip the bin manager
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e '{"dotfiles_skip_tools":["bin"]}'
```

### Choosing Stow Packages
Each profile declares its default packages in `ansible/profiles/<profile>.yml` (`dotfiles_profile_stow_packages`); new top-level directories are not linked until added there. Override or exclude packages per run:
```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
  -e '{"dotfiles_stow_packages":["zsh","tmux"],"dotfiles_stow_skip_packages":["tmux"]}'
```
- `dotfiles_stow_packages` replaces the profile default; `dotfiles_stow_skip_packages` is removed from either list.
- Unknown package names fail. Existing conflicting files are left untouched and reported (`-e dotfiles_stow_strict=true` fails instead).
- `dotfiles_stow_target` only changes where configs are linked, not where tool installers write.
- Package installation, config linking (`--tags stow`) and user tools (`--tags tools`) are separate steps; linking fewer packages does not install fewer applications.
- `dotfiles_skip_tools` currently supports only `bin`.

### Package Drift Report
Package manifests are curated by hand; a dump of everything installed would pull in dependencies, OS defaults, and machine-specific tools. Instead, a read-only report shows what differs:
```sh
python3 ansible/scripts/package-report.py            # print to the terminal
python3 -m unittest ansible/tests/test_package_report.py
```
- `+` lines are installed (explicitly) but not in the manifest; `-` lines are in the manifest but not installed here (possibly intentional). Review, edit the file in `ansible/packages/`, and commit yourself. Nothing is installed, removed, edited, or committed.
- Covers Homebrew formulae/casks/taps and Brewfile VS Code extensions (macOS), DNF + Flatpak (Fedora), APT + Snap (Ubuntu). Options: `--skip NAME`, `--no-flatpak`, `--no-snap`. Mise runtimes, plugins, and manually downloaded binaries are not covered.
- Exit status `2` means a source was unavailable or failed, so its section is incomplete (it never produces false "missing" entries).

Optional weekly report (off by default; Mondays 09:00 via a per-user LaunchAgent on macOS, a systemd user timer on Linux). The latest report is written to `~/.local/state/dotfiles/package-report.txt`:
```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags package-report -e dotfiles_package_report_schedule=true
# Without a systemd user manager (e.g. some WSL setups), also allow a cron job:
#   -e dotfiles_package_report_cron_fallback=true
# Disable and remove the job:
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags package-report
```
The machine must be on and logged in; cron does not replay missed runs, systemd timers do (`Persistent=true`).

---

### WSL & macOS Notes
- **WSL**: The bootstrap script disables Snap installation (`snapd` often requires systemd). When running the playbook directly, pass `-e dotfiles_install_snap_apps=false`.
- **macOS**: Ensure Homebrew is installed before running the bootstrap script.

---

## 🔍 How it Works (Deep Dive)

The automated setup is a wrapper around a set of manual steps. If you are curious about exactly what is being installed or want to perform a specific step manually, please refer to the **[Manual Installation Guide](INSTALL_MANUAL.md)**.

### Manual Playbook Execution
If you already have Ansible installed and want to run the playbook manually:
```sh
# Fedora/Ubuntu
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass

# macOS
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e '{"dotfiles_skip_tools":["bin"]}'
```

To run the **server profile** manually:
```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass -e dotfiles_profile=server
```

### Testing in Containers
You can test the provisioning without affecting your host system using the provided Dockerfiles:
```sh
docker build -f ansible/containers/fedora.Dockerfile -t dotfiles-test:fedora .
docker run --rm dotfiles-test:fedora
```

### Testing Stow Selection
`bash ansible/containers/test-stow.sh` checks package selection, overrides, and conflict handling against disposable target directories (requires `stow` and `ansible-playbook`).

To test the **server profile** (use `BASE_IMAGE=debian:13` for Debian; Docker is only needed for these tests):
```sh
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -f ansible/containers/server.Dockerfile -t dotfiles-test:server .
docker run --rm dotfiles-test:server
```
