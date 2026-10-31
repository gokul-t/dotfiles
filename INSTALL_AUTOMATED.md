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
   - Install all system packages listed in `dnf-packages.txt` or `ubuntu-packages.txt`.
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
- **Preserved**: Existing login shell and Bash configuration.

---

## ⚙️ Customization

### Skipping Tools
If you want to skip specific tools (e.g., the `bin` manager), you can pass extra variables to the playbook:
```sh
# Example: Skip the bin manager
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e '{"dotfiles_skip_tools":["bin"]}'
```

### WSL & macOS Notes
- **WSL**: Snap installation is automatically disabled as `snapd` often requires systemd.
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

To test the **server profile** (e.g., on Ubuntu):
```sh
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -f ansible/containers/server.Dockerfile -t dotfiles-test:server .
docker run -e DOTFILES_ANSIBLE_EXTRA_VARS="dotfiles_profile=server" --rm dotfiles-test:server
```
