#!/usr/bin/env bash

set -euo pipefail

readonly REPOSITORY_URL="https://github.com/gokul-t/dotfiles.git"
readonly DOTFILES_DIR="${HOME:-}/.dotfiles"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
  fail "HOME is unset or points to '/'. Run this script as your regular user."
fi

if [[ "$(id -u)" -eq 0 ]]; then
  fail "Run this script as your regular user, not as root."
fi

platform=""
case "$(uname -s)" in
  Darwin)
    platform="macos"
    ;;
  Linux)
    if [[ ! -r /etc/os-release ]]; then
      fail "Cannot identify this Linux distribution: /etc/os-release is unavailable."
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
      fedora)
        platform="fedora"
        ;;
      ubuntu)
        platform="ubuntu"
        ;;
      *)
        fail "Unsupported Linux distribution '${ID:-unknown}'. Supported: Fedora and Ubuntu/WSL."
        ;;
    esac
    ;;
  *)
    fail "Unsupported operating system. Supported: Fedora, Ubuntu/WSL, and macOS."
    ;;
esac

packages=()
if ! command -v git >/dev/null 2>&1; then
  packages+=(git)
fi
if ! command -v ansible-playbook >/dev/null 2>&1; then
  packages+=(ansible-core)
fi

if ((${#packages[@]})); then
  case "$platform" in
    fedora)
      command -v sudo >/dev/null 2>&1 || fail "Install sudo to bootstrap system packages."
      sudo dnf install -y "${packages[@]}"
      ;;
    ubuntu)
      command -v sudo >/dev/null 2>&1 || fail "Install sudo to bootstrap system packages."
      sudo apt-get update
      sudo apt-get install -y "${packages[@]}"
      ;;
    macos)
      command -v brew >/dev/null 2>&1 || fail "Install Homebrew first: https://brew.sh/"
      brew install "${packages[@]/ansible-core/ansible}"
      ;;
  esac
fi

command -v git >/dev/null 2>&1 || fail "Git is required but was not installed."
command -v ansible-playbook >/dev/null 2>&1 || fail "Ansible is required but was not installed."

if [[ -e "$DOTFILES_DIR" || -L "$DOTFILES_DIR" ]]; then
  [[ -d "$DOTFILES_DIR" ]] || fail "$DOTFILES_DIR exists but is not a directory."
  checkout_root="$(git -C "$DOTFILES_DIR" rev-parse --show-toplevel 2>/dev/null)" \
    || fail "$DOTFILES_DIR exists but is not a Git checkout. Move it aside and retry."
  actual_root="$(cd "$DOTFILES_DIR" && pwd -P)"
  [[ "$actual_root" == "$checkout_root" && -f "$DOTFILES_DIR/ansible/site.yml" ]] \
    || fail "$DOTFILES_DIR is not a valid dotfiles checkout. Move it aside and retry."
  printf 'Using existing checkout at %s (not updating it).\n' "$DOTFILES_DIR"
else
  printf 'Cloning dotfiles into %s...\n' "$DOTFILES_DIR"
  git clone "$REPOSITORY_URL" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"
ansible_args=(-i ansible/inventory.ini ansible/site.yml)
if [[ "$platform" != "macos" ]]; then
  ansible_args+=(--ask-become-pass)
fi
if [[ "$platform" == "ubuntu" ]] \
  && { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease; }; then
  ansible_args+=(-e dotfiles_install_snap_apps=false)
fi

ansible-playbook "${ansible_args[@]}"
