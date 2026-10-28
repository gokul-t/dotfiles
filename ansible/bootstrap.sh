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

is_wsl=false
if [[ "$platform" == "ubuntu" ]] \
  && { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease; }; then
  is_wsl=true
fi

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
if [[ "$is_wsl" == true ]]; then
  ansible_args+=(-e dotfiles_install_snap_apps=false)
fi

ansible-playbook "${ansible_args[@]}"

if [[ "$platform" == "fedora" || ( "$platform" == "ubuntu" && "$is_wsl" == false ) ]]; then
  if [[ -d "$HOME/.config/toshy" ]]; then
    printf 'Toshy is already installed; skipping the optional Toshy setup.\n'
  else
    printf '\nToshy is an optional keyboard remapper that makes Linux shortcuts more like macOS.\n'
    printf 'It requires a supported Fedora/Ubuntu system, a compatible desktop/session, and admin access.\n'
    printf 'Use a fully updated system. On Wayland, only certain desktops are supported; GNOME needs a compatible extension.\n'
    printf 'The installer checks system readiness and may install system packages or configure services.\n'
    printf 'Requirements: https://github.com/RedBearAK/Toshy#requirements\n'
    printf 'Supported desktops: https://github.com/RedBearAK/Toshy#currently-working-desktop-environments-or-window-managers\n'
    if [[ -r /dev/tty ]]; then
      printf 'Would you like to install Toshy? [y/N] ' >&2
      IFS= read -r toshy_choice < /dev/tty || toshy_choice=""
    else
      toshy_choice=""
      printf 'No interactive terminal; skipping optional Toshy installation.\n'
    fi

    if [[ "${toshy_choice,,}" == "y" || "${toshy_choice,,}" == "yes" ]]; then
      toshy_bootstrap_file="$(mktemp)"
      trap 'rm -f -- "$toshy_bootstrap_file"' EXIT
      curl -fsSL \
        https://raw.githubusercontent.com/RedBearAK/toshy/main/scripts/bootstrap.sh \
        -o "$toshy_bootstrap_file"
      bash "$toshy_bootstrap_file" </dev/tty
    else
      printf 'Skipping optional Toshy installation.\n'
    fi
  fi
fi
