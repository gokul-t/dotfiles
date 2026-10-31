#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
target=/tmp/dotfiles-test-home

for rel in .zshrc .zshenv .tmux.conf .config/nvim bin/sesh-session-picker; do
  resolved="$(readlink -f "$target/$rel")"
  case "$resolved" in
    "$repo_root"/*) ;;
    *) printf 'FAIL: %s does not resolve into the repository (%s).\n' "$rel" "$resolved"; exit 1 ;;
  esac
done
printf 'PASS: Representative workstation links resolve to the repository.\n'
