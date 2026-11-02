#!/usr/bin/env bash

set -euo pipefail

readonly REPOSITORY_URL="https://github.com/gokul-t/dotfiles.git"
readonly DOTFILES_DIR="${HOME:-}/.dotfiles"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf "Usage: %s [--profile personal|work|server|workstation] [options]\n" "$0"
  printf "Options:\n"
  printf "  --profile PROFILE  Select setup mode: personal, work, or server\n"
  printf "                     default: shared workstation setup without private settings\n"
  printf "                     workstation is an alias for that shared setup\n"
  printf "  --help             Show this help message\n"
}

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
  fail "HOME is unset or points to '/'. Run this script as your regular user."
fi

if [[ "$(id -u)" -eq 0 ]]; then
  fail "Run this script as your regular user, not as root."
fi

dotfiles_profile="workstation"
dotfiles_mode="none"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ -z "${2:-}" ]]; then
        fail "--profile requires an argument."
      fi
      case "$2" in
        personal)
          dotfiles_profile="workstation"
          dotfiles_mode="personal"
          ;;
        workstation)
          dotfiles_profile="workstation"
          dotfiles_mode="none"
          ;;
        work)
          dotfiles_profile="workstation"
          dotfiles_mode="work"
          ;;
        server)
          dotfiles_profile="server"
          dotfiles_mode="none"
          ;;
        *)
          fail "Unsupported profile '$2'. Supported: personal, work, server, workstation."
          ;;
      esac
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option '$1'. Use --help for usage."
      ;;
  esac
done

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
      debian)
        if [[ "$dotfiles_profile" == "server" ]]; then
          platform="debian"
        else
          fail "Debian is only supported for the 'server' profile. Use --profile server."
        fi
        ;;
      *)
        fail "Unsupported Linux distribution '${ID:-unknown}'. Supported: Fedora and Ubuntu/WSL (Debian with --profile server)."
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
    ubuntu|debian)
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

work_enabled=false
personal_enabled=false
if [[ "$dotfiles_profile" == "workstation" ]]; then
  if [[ "$dotfiles_mode" == "work" ]]; then
    work_path="$DOTFILES_DIR/work"
    work_configured=false
    if git -C "$DOTFILES_DIR" config -f .gitmodules --get submodule.work.path >/dev/null 2>&1; then
      work_configured=true
    fi

    if [[ "$work_configured" == true ]]; then
      git -C "$DOTFILES_DIR" submodule update --init work \
        || fail "Could not initialize the configured work submodule."
    elif [[ ! -f "$work_path/.config/mise/config.local.toml" || ! -f "$work_path/ansible/packages/Brewfile" ]]; then
      work_url=""
      if exec 3<>/dev/tty 2>/dev/null; then
        printf 'Private work submodule URL (leave blank to skip work settings): ' >&3
        IFS= read -r work_url <&3 || work_url=""
        exec 3>&-
      else
        printf 'No terminal available to request a work submodule URL; skipping private work settings.\n' >&2
      fi

      if [[ -n "$work_url" ]]; then
        [[ ! -e "$work_path" && ! -L "$work_path" ]] \
          || fail "$work_path already exists but is not a configured work submodule. Move it aside and retry."
        git -C "$DOTFILES_DIR" submodule add --name work "$work_url" ./work \
          || fail "Could not add the work submodule."
        printf 'Added work submodule locally. Bootstrap will not commit or push its URL.\n'
      else
        printf 'Continuing without personal or work-specific settings.\n'
      fi
    fi

    if [[ -f "$work_path/.config/mise/config.local.toml" && -f "$work_path/ansible/packages/Brewfile" ]]; then
      work_enabled=true
    elif [[ "$work_configured" == true || -n "${work_url:-}" ]]; then
      fail "The work submodule is missing required files (mise config overlay and Brewfile)."
    fi
  elif [[ "$dotfiles_mode" == "personal" ]]; then
    git -C "$DOTFILES_DIR" submodule update --init personal \
      || fail "Could not initialize the personal submodule."
    personal_enabled=true
  fi
fi

cd "$DOTFILES_DIR"
ansible_args=(-i ansible/inventory.ini ansible/site.yml)
if [[ "$platform" != "macos" ]]; then
  ansible_args+=(--ask-become-pass)
fi
if [[ "$is_wsl" == true ]]; then
  ansible_args+=(-e dotfiles_install_snap_apps=false)
fi
ansible_args+=(-e dotfiles_profile="$dotfiles_profile")
if [[ "$dotfiles_profile" == "workstation" ]]; then
  ansible_args+=(-e dotfiles_work_enabled="$work_enabled")
  ansible_args+=(-e dotfiles_personal_enabled="$personal_enabled")
fi

ansible-playbook "${ansible_args[@]}"

if [[ "$dotfiles_profile" == "workstation" ]] && { [[ "$platform" == "fedora" ]] || ( [[ "$platform" == "ubuntu" ]] && [[ "$is_wsl" == false ]] ); }; then
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
