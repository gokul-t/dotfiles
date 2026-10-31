#!/usr/bin/env bash
# Exercises Stow package selection against disposable targets; never touches $HOME.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

run_stow() {
  local target="$1"; shift
  ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
    -e "dotfiles_stow_target=$target" "$@"
}

# Default workstation selection links profile packages, not undeclared directories.
mkdir -p "$work/default" "$repo_root/zz-undeclared/.config"
touch "$repo_root/zz-undeclared/.config/undeclared"
trap 'rm -rf "$work" "$repo_root/zz-undeclared"' EXIT
run_stow "$work/default" | tee "$work/first.log"
grep -Eq 'changed=[1-9]' "$work/first.log" || fail "first run did not report changes"
[[ "$(readlink -f "$work/default/.vimrc")" == "$repo_root/vim/.vimrc" ]] || fail ".vimrc not linked"
[[ "$(readlink -f "$work/default/.tmux.conf")" == "$repo_root/tmux/.tmux.conf" ]] || fail ".tmux.conf not linked"
[[ ! -e "$work/default/.config/undeclared" ]] || fail "undeclared package was linked"
run_stow "$work/default" | tee "$work/second.log"
grep -Eq 'changed=0' "$work/second.log" || fail "second run reported changes"

# Explicit override and exclusions.
mkdir -p "$work/override"
run_stow "$work/override" -e '{"dotfiles_stow_packages":["vim","tmux"],"dotfiles_stow_skip_packages":["tmux"]}' >/dev/null
[[ -L "$work/override/.vimrc" ]] || fail "override did not link vim"
[[ ! -e "$work/override/.tmux.conf" ]] || fail "exclusion not applied to explicit list"

# Unknown package fails; empty effective selection is a no-op.
mkdir -p "$work/unknown"
if run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["nope"]}' >/dev/null 2>&1; then
  fail "unknown package did not fail"
fi
run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_stow_skip_packages":["vim"]}' >/dev/null
[[ ! -e "$work/unknown/.vimrc" ]] || fail "empty selection linked a package"

# Conflicts preserve files and fail only in strict mode.
mkdir -p "$work/conflict"
printf 'local\n' > "$work/conflict/.vimrc"
run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"]}' >/dev/null
[[ ! -L "$work/conflict/.vimrc" && "$(cat "$work/conflict/.vimrc")" == local ]] || fail "conflicting file overwritten"
if run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_stow_strict":true}' >/dev/null 2>&1; then
  fail "strict mode did not fail"
fi

printf 'All Stow selection checks passed.\n'
