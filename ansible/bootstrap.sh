#!/usr/bin/env bash

set -euo pipefail

readonly REPOSITORY_URL="https://github.com/gokul-t/dotfiles.git"
readonly DOTFILES_DIR="${HOME:-}/.dotfiles"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf "Usage: %s [--profile default|personal|work|server] [options]\n" "$0"
  printf "Options:\n"
  printf "  --profile PROFILE  Select setup mode: default, personal, work, or server\n"
  printf "                     default: shared public workstation setup (no private settings)\n"
  printf "                     personal: shared workstation plus the private 'personal' overlay\n"
  printf "                     work: shared workstation plus the private 'work' overlay\n"
  printf "                     server: minimal server profile (no GUI apps, lean packages)\n"
  printf "  --help             Show this help message\n"
}

if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
  fail "HOME is unset or points to '/'. Run this script as your regular user."
fi

if [[ "$(id -u)" -eq 0 ]]; then
  fail "Run this script as your regular user, not as root."
fi

dotfiles_profile="default"
dotfiles_private_enabled=false
dotfiles_private_profile=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ -z "${2:-}" ]]; then
        fail "--profile requires an argument."
      fi
      case "$2" in
        default)
          dotfiles_profile="default"
          ;;
        personal)
          dotfiles_profile="personal"
          dotfiles_private_enabled=true
          dotfiles_private_profile="personal"
          ;;
        work)
          dotfiles_profile="work"
          dotfiles_private_enabled=true
          dotfiles_private_profile="work"
          ;;
        server)
          dotfiles_profile="server"
          ;;
        *)
          fail "Unsupported profile '$2'. Supported: default, personal, work, server."
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

dotfiles_overlay_initialized=false

dotfiles_overlay_required_files() {
  case "$1" in
    personal)
      cat <<'EOF'
.identity.conf
.config/zsh/user-env.d/env.zsh
ansible/packages/Brewfile
ansible/packages/dnf-packages.txt
ansible/packages/flatpak-packages.txt
ansible/packages/ubuntu-packages.txt
ansible/packages/ubuntu-snap-packages.txt
EOF
      ;;
    work)
      cat <<'EOF'
.config/mise/config.local.toml
ansible/packages/Brewfile
EOF
      ;;
    *)
      return 0
      ;;
  esac
}

init_dotfiles_overlay() {
  local overlay_name="$1"
  local overlay_path="${DOTFILES_DIR}/${overlay_name}"
  local overlay_key=""
  local overlay_value=""

  while read -r overlay_key overlay_value; do
    if [[ "$overlay_value" == "$overlay_name" || "$overlay_value" == "./${overlay_name}" ]]; then
      break
    fi
  done < <(git -C "$DOTFILES_DIR" config -f "${DOTFILES_DIR}/.gitmodules" --get-regexp '^submodule\.' 2>/dev/null || true)

  if [[ -n "$overlay_key" ]]; then
    git -C "$DOTFILES_DIR" submodule update --init "$overlay_name" \
      || fail "Could not initialize the '${overlay_name}' submodule."
    dotfiles_overlay_initialized=true
    return 0
  fi

  local overlay_url=""
  if exec 3<>/dev/tty 2>/dev/null; then
    printf 'Private %s submodule URL (leave blank to skip private settings): ' "$overlay_name" >&3
    IFS= read -r overlay_url <&3 || overlay_url=""
    exec 3>&-
  else
    printf 'No terminal available to request a %s submodule URL; skipping private settings.\n' "$overlay_name" >&2
  fi

  if [[ -n "$overlay_url" ]]; then
    [[ ! -e "$overlay_path" && ! -L "$overlay_path" ]] \
      || fail "${overlay_path} already exists but is not a configured ${overlay_name} submodule. Move it aside and retry."
    git -C "$DOTFILES_DIR" submodule add --name "$overlay_name" "$overlay_url" "./${overlay_name}" \
      || fail "Could not add the ${overlay_name} submodule."
    printf 'Added %s submodule locally. Bootstrap will not commit or push its URL.\n' "$overlay_name"
  fi

  if [[ -n "$overlay_url" ]]; then
    dotfiles_overlay_initialized=true
  fi
}

if [[ "$dotfiles_private_enabled" == true ]]; then
  init_dotfiles_overlay "$dotfiles_private_profile"
  if [[ "$dotfiles_overlay_initialized" == true ]]; then
    while read -r overlay_required_file; do
      [[ -n "$overlay_required_file" ]] || continue
      if [[ ! -f "${DOTFILES_DIR}/${dotfiles_private_profile}/${overlay_required_file}" ]]; then
        fail "The '${dotfiles_private_profile}' submodule is missing required file '${overlay_required_file}'."
      fi
    done < <(dotfiles_overlay_required_files "$dotfiles_private_profile")
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
if [[ "$dotfiles_private_enabled" == true ]]; then
  ansible_args+=(-e dotfiles_private_enabled=true)
  ansible_args+=(-e dotfiles_private_profile="$dotfiles_private_profile")
fi

ansible-playbook "${ansible_args[@]}"

if [[ "$dotfiles_profile" != "server" ]] && { [[ "$platform" == "fedora" ]] || ( [[ "$platform" == "ubuntu" ]] && [[ "$is_wsl" == false ]] ); }; then
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
