# Automated Installation Guide

This guide describes how to set up your environment automatically using Ansible. This is the fastest way to get the full experience.

## 🚀 One-Command Setup

Run the following command from your terminal as a regular user:

```sh
curl -fsSL https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh | bash
```

### What this does:
1. **Bootstraps**: Installs Ansible and Git using the native package manager (`dnf` for Fedora, `apt` for Ubuntu/Debian and derivatives (incl. WSL), `brew` for macOS).
2. **Clones**: Pulls this repository into `~/.dotfiles`.
3. **Provisions**: Runs the Ansible playbook to:
   - Install all system packages listed in `ansible/packages/` (`dnf-packages.txt`, `apt-packages.txt`, or `Brewfile`).
   - Install Flatpak/Snap applications.
   - Configure repositories for RPM Fusion (free/nonfree), VS Code, Chrome, etc.
   - Use **GNU Stow** to symlink all configurations to your home directory.
   - Set up shell plugins and development tools (`mise`, etc.).
   - (Optional) Install **Toshy** for macOS-like keyboard shortcuts on Linux.

With the default profile selected, bootstrap installs the shared public workstation configuration only. It does not initialize or link the private personal or work settings.

## 🖥️ Supported Operating Systems

| Platform | Profiles |
|---|---|
| Fedora (current stable) | all |
| RedHat Enterprise Linux 9+ and derivatives (Rocky Linux, AlmaLinux, CentOS Stream) | server |
| macOS | all |
| Ubuntu 24.04+ and derivatives based on it (Linux Mint 22, Pop!_OS 24.04, Zorin 18, Kali, ...), incl. WSL | all |
| Debian 13+ and derivatives based on it (Raspberry Pi OS trixie, ...), incl. WSL | all |

Notes:
- Minimum versions are enforced: Ubuntu 24.04 and Debian 13 (trixie) are the floors; older releases fail fast with a clear error. RedHat 9 is the floor for RedHat-family server installs.
- Derivatives are supported when based on those floors.
- Snap is off by default on non-Ubuntu Debian-family systems; opt in with `-e dotfiles_install_snap_apps=true`.
- Anything outside this list fails fast with a message naming the supported platforms.

---

## 🏠 Homelab Server Setup

For minimal server installations (Ubuntu 24.04+, Debian 13+, or RedHat Enterprise Linux 9+ and derivatives), use the `server` profile. This installs only a lean set of essentials, skips GUI apps, and avoids changing your login shell.

```sh
curl -fsSL https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh | bash -s -- --profile server
```

### Server Profile Details:
- **Supported OS**: Ubuntu 24.04+, Debian 13+, or RedHat 9+ (RHEL, Rocky Linux, AlmaLinux, CentOS Stream).
- **Installed**: Core utilities (`curl`, `git`, `vim`, `tmux`, `htop`, `ripgrep`, `jq`, etc.).
- **Stowed**: Only the `vim` configuration.
- **Preserved**: Existing login shell and Bash configuration. tmux uses its defaults (the workstation tmux config is not linked).
- **Not touched**: GUI apps, language runtimes, Zsh/plugins, Docker, SSH daemon, firewall, users, and services.
- **Prerequisites**: Run locally (e.g. over SSH) as a regular user with `sudo` and network access, not as root, and on a supported RedHat-family release (9+) or Debian-family release (13+).
- **RedHat-family package sources**: On RHEL/Fedora-based systems the playbook enables the EPEL repository before installing the server package set (Fedora already ships EPEL enabled by default).
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
Each profile declares its default packages in `ansible/profiles/<profile>.yml` (`dotfiles_profile_stow_packages`); new top-level directories are not linked until added there. The `personal` and `work` overlays layer the default profile plus their private overlay. Override or exclude packages per run:
```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
  -e '{"dotfiles_stow_packages":["zsh","tmux"],"dotfiles_stow_skip_packages":["tmux"]}'
```
- `dotfiles_stow_packages` replaces the profile default; `dotfiles_stow_skip_packages` is removed from either list.
- Unknown package names fail. Existing conflicting files are left untouched and reported (`-e dotfiles_stow_strict=true` fails instead).
- `dotfiles_stow_target` only changes where configs are linked, not where tool installers write.
- Package installation, config linking (`--tags stow`) and user tools (`--tags tools`) are separate steps; linking fewer packages does not install fewer applications.
- `dotfiles_skip_tools` currently supports only `bin`.

### Personal and Work Settings

**Key symmetry**: Both `personal` and `work` overlays can include the same types of files:
- `ansible/packages/Brewfile` (macOS Homebrew packages)
- `.config/mise/config.local.toml` (mise tool versioning config)
- OS-specific package manifests (Fedora DNF/Flatpak, Ubuntu/Debian APT/Snap, macOS Brewfile)
- Home-layout dotfiles (`.identity.conf`, `.config/zsh/...`, etc.)

**All files are optional**: Only include what you need in your overlay. Missing files are silently skipped.

Select personal mode:
```sh
./ansible/bootstrap.sh --profile personal
```

Work and personal settings are mutually exclusive. Select work mode:
```sh
./ansible/bootstrap.sh --profile work
```
- If the `work` submodule is not already present, bootstrap prompts for its private repository URL. Leave the URL blank to continue with shared workstation configuration only.
- On macOS an overlay Brewfile runs before the shared one; a warning is printed if an existing tap's remote differs. Brew Bundle leaves existing tap remotes untouched; retap manually if needed.
- Selecting a different mode later is not an undo: old links remain. Remove work links with `stow --dir ~/.dotfiles --target ~ --delete work`; personal links with `stow --dir ~/.dotfiles --target ~ --delete personal`.


### Package Drift Report
Package manifests are curated by hand; a dump of everything installed would pull in dependencies, OS defaults, and machine-specific tools. Instead, a read-only report shows what differs:
```sh
user-installed-packages report --manifest-dir ~/.dotfiles/ansible/packages \
  --apt-manifest apt-packages.txt \
  --apt-manifest ~/.dotfiles/personal/ansible/packages/apt-packages.txt \
  --snap-manifest snap-packages.txt \
  --snap-manifest ~/.dotfiles/personal/ansible/packages/snap-packages.txt
```
The [user-installed-packages](https://github.com/gokul-t/user-installed-packages) project provides the report command and the explicit APT/DNF package detection it uses. The playbook installs it via `pipx` into `~/.local/bin` on macOS, Fedora, and Ubuntu/Debian (`dotfiles_user_installed_packages_version` in `ansible/vars.yml` pins the release; bump it deliberately). To install by hand instead:
```sh
pipx install git+https://github.com/gokul-t/user-installed-packages.git@v0.5.0
```
- `+` lines are installed (explicitly) but not in the manifest; `-` lines are in the manifest but not installed here (possibly intentional). Review and edit the corresponding file in `ansible/packages/` or, for personal entries, `personal/ansible/packages/`. Nothing is installed, removed, or committed by the report.
- Covers Homebrew formulae/casks/taps and Brewfile VS Code extensions (macOS), DNF + Flatpak (Fedora), APT + Snap (Ubuntu/Debian). Options: `--skip NAME`, `--no-flatpak`, `--no-snap`. Mise runtimes, plugins, and manually downloaded binaries are not covered.
- `--manifest-dir` defaults to `./ansible/packages`. Per-package options (`--dnf-manifest`, `--apt-manifest`, `--flatpak-manifest`, `--snap-manifest`, `--brewfile`) accept paths or filenames relative to that directory, and may be repeated to compare shared and private manifests together. Personal mode passes the public and private manifest paths directly to the report command; no copied/merged report manifests are needed.
- The DNF check compares only command-line-installed (`reason=User`) packages. OS-image packages are detected from the earliest dnf history transactions (falling back to an install-time window on machines without usable history). Group and dependency installs (including image group installs) and kernels installed by system updates are not compared.
- Detection for DNF and APT uses the user-installed-packages library; see its README for the exact algorithm and known limitations (e.g. the apt check subtracts the installer-recorded base set from `/var/log/installer/initial-status.gz`, and image group installs can never be told apart in general). Degradations (missing installer log, missing dnf history) are surfaced as warnings in the report notes.
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
- **WSL**: The bootstrap script disables Snap installation on WSL (`snapd` often requires systemd), on any Linux distribution. When running the playbook directly, pass `-e dotfiles_install_snap_apps=false`.
- **Debian-family "derivatives"**: Linux Mint, Pop!_OS, Zorin, etc. are recognized through `ID_LIKE`; support requires a base on Ubuntu 24.04+ or Debian 13+. Snap is off by default outside Ubuntu (opt in with `-e dotfiles_install_snap_apps=true`).
- **macOS**: Ensure Homebrew is installed before running the bootstrap script.

---

## 🔍 How it Works (Deep Dive)

The automated setup is a wrapper around a set of manual steps. If you are curious about exactly what is being installed or want to perform a specific step manually, please refer to the **[Manual Installation Guide](INSTALL_MANUAL.md)**.

### Manual Playbook Execution
If you already have Ansible installed and want to run the playbook manually:
```sh
# Fedora/Ubuntu/Debian/RedHat-family
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass

# macOS
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e '{"dotfiles_skip_tools":["bin"]}'
```

To run the **server profile** manually:
```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass -e dotfiles_profile=server
```

### Testing in Containers
You can test the provisioning without affecting your host system using the provided Dockerfiles (the Ubuntu image is parameterized; pass `BASE_IMAGE` for Debian):
```sh
docker build -f ansible/containers/fedora.Dockerfile -t dotfiles-test:fedora .
docker run --rm dotfiles-test:fedora

docker build --build-arg BASE_IMAGE=debian:13 \
  -f ansible/containers/ubuntu.Dockerfile -t dotfiles-test:debian .
docker run --rm dotfiles-test:debian
```

### Testing Stow Selection
`bash ansible/containers/test-stow.sh` checks package selection, overrides, and conflict handling against disposable target directories (requires `stow` and `ansible-playbook`).

To test the **server profile** (use `BASE_IMAGE=debian:13` for Debian; Docker is only needed for these tests):
```sh
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -f ansible/containers/server.Dockerfile -t dotfiles-test:server .
docker run --rm dotfiles-test:server
```
