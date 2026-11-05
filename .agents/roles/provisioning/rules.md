# Provisioning System Role

## Core Files

| File | Purpose |
|------|---------|
| `ansible/site.yml` | Main orchestration entry point |
| `ansible/tasks/stow.yml` | Links packages with stow |
| `ansible/tasks/user-tools.yml` | Installs Oh My Zsh, TPM, LazyVim, mise |
| `ansible/profiles/*.yml` | Package lists per profile |
| `ansible/packages/` | OS-specific package manifests |
| `ansible/containers/*` | Test scripts |

## Validation

```sh
# Ansible syntax
ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check

# Stow test
stow ansible
```

## Supported OS

- Fedora, RHEL 9+, Rocky Linux, AlmaLinux
- Ubuntu 24.04+, Debian 13+, WSL
- macOS

## Profiles

| Profile | Purpose |
|---------|---------|
| Default | Workstation setup |
| Personal | Personal overlays |
| Work | Work overlays |
| Server | Minimal server setup |
