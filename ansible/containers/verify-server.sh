#!/usr/bin/env bash
set -euo pipefail

printf "Starting server provisioning verification...\n"

# 1. Check for essential packages
# Mapping: verification_binary -> package_name (for logging)
declare -A PKG_MAP=(
  ["vim"]="vim"
  ["tmux"]="tmux"
  ["htop"]="htop"
  ["rg"]="ripgrep"
  ["jq"]="jq"
  ["stow"]="stow"
)

for bin in "${!PKG_MAP[@]}"; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf "FAIL: Essential package '%s' (binary '%s') is not installed.\n" "${PKG_MAP[$bin]}" "$bin"
    exit 1
  fi
done
printf "PASS: Essential packages are installed.\n"

# 2. Check for Vim symlink
if [[ ! -L "$HOME/.vimrc" ]]; then
  printf "FAIL: ~/.vimrc is not a symlink.\n"
  exit 1
fi
TARGET=$(readlink -f "$HOME/.vimrc")
if [[ "$TARGET" != *"/vim/.vimrc"* ]]; then
  printf "FAIL: ~/.vimrc does not point to the dotfiles repository. Target: %s\n" "$TARGET"
  exit 1
fi
printf "PASS: Vim configuration is correctly linked.\n"

# 3. Check login shell (should remain bash for server profile)
CURRENT_USER="${USER:-$(id -un)}"
CURRENT_SHELL=$(getent passwd "$CURRENT_USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "/bin/bash" ]]; then
  printf "FAIL: Login shell was changed to '%s', but should remain /bin/bash.\n" "$CURRENT_SHELL"
  exit 1
fi
printf "PASS: Login shell is preserved as /bin/bash.\n"

# 4. Negative checks: Ensure workstation/GUI artifacts are absent
UNWANTED=("zsh" "google-chrome" "code")
for tool in "${UNWANTED[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf "FAIL: Unwanted tool '%s' was found installed.\n" "$tool"
    exit 1
  fi
done
printf "PASS: No unwanted workstation artifacts found.\n"

for rel in .bashrc .bash_profile .tmux.conf .zshrc .config/nvim; do
  if [[ -L "$HOME/$rel" ]]; then
    printf "FAIL: Unexpected workstation symlink ~/%s.\n" "$rel"
    exit 1
  fi
done
for rel in .oh-my-zsh .tmux .lazy-idea .local/bin/mise; do
  if [[ -e "$HOME/$rel" ]]; then
    printf "FAIL: Unexpected workstation artifact ~/%s.\n" "$rel"
    exit 1
  fi
done
printf "PASS: No workstation dotfiles or tools were linked.\n"

# 5. Smoke-test Vim with the linked config and tmux on an isolated socket
vim -es -u "$HOME/.vimrc" -c 'qa!' || { printf "FAIL: Vim could not load ~/.vimrc.\n"; exit 1; }
socket="dotfiles-verify-$$"
tmux -L "$socket" -f /dev/null new-session -d 'sleep 30'
tmux -L "$socket" list-sessions >/dev/null
tmux -L "$socket" kill-server
printf "PASS: Vim and tmux smoke tests.\n"

# 6. Existing files must survive Stow conflicts; strict mode must fail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
rm -f "$HOME/.vimrc"
printf '" local\n' > "$HOME/.vimrc"
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow -e dotfiles_profile=server >/dev/null
if [[ -L "$HOME/.vimrc" || "$(cat "$HOME/.vimrc")" != '" local' ]]; then
  printf "FAIL: Existing ~/.vimrc was overwritten.\n"
  exit 1
fi
if ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
  -e dotfiles_profile=server -e dotfiles_stow_strict=true >/dev/null 2>&1; then
  printf "FAIL: Strict mode did not fail on a Stow conflict.\n"
  exit 1
fi
printf "PASS: Stow conflicts preserve existing files and fail in strict mode.\n"

printf "\nAll server verification checks PASSED!\n"
