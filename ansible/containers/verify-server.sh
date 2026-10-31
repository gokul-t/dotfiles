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

printf "\nAll server verification checks PASSED!\n"
