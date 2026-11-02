#!/usr/bin/env bash
# Exercises Stow package selection against disposable targets; never touches $HOME.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

work="$(mktemp -d)"
trap 'rm -rf "$work" "$repo_root/zz-undeclared"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

run_stow() {
  local target="$1"; shift
  ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
    -e "dotfiles_stow_target=$target" "$@"
}

# Default workstation selection links profile packages and personal settings, not undeclared directories.
mkdir -p "$work/default" "$repo_root/zz-undeclared/.config"
touch "$repo_root/zz-undeclared/.config/undeclared"
default_args=()
if [[ -f "$repo_root/personal/.identity.conf" && -f "$repo_root/personal/.config/zsh/user-env.d/env.zsh" ]]; then
  default_args=(-e '{"dotfiles_stow_packages":["vim","tmux"]}' -e dotfiles_personal_enabled=true)
  test_personal_overlay=true
else
  default_args=(-e '{"dotfiles_stow_packages":["vim","tmux"]}' -e dotfiles_personal_enabled=false)
  test_personal_overlay=false
fi
run_stow "$work/default" "${default_args[@]}" | tee "$work/first.log"
grep -Eq 'changed=[1-9]' "$work/first.log" || fail "first run did not report changes"
[[ "$(readlink -f "$work/default/.vimrc")" == "$repo_root/vim/.vimrc" ]] || fail ".vimrc not linked"
[[ "$(readlink -f "$work/default/.tmux.conf")" == "$repo_root/tmux/.tmux.conf" ]] || fail ".tmux.conf not linked"
if [[ "$test_personal_overlay" == true ]]; then
  [[ "$(readlink -f "$work/default/.identity.conf")" == "$repo_root/personal/.identity.conf" ]] || fail "personal identity not linked by default"
fi
[[ ! -e "$work/default/.config/undeclared" ]] || fail "undeclared package was linked"
run_stow "$work/default" "${default_args[@]}" | tee "$work/second.log"
grep -Eq 'changed=0' "$work/second.log" || fail "second run reported changes"

# Explicit override and exclusions.
mkdir -p "$work/override"
run_stow "$work/override" -e '{"dotfiles_stow_packages":["vim","tmux"],"dotfiles_stow_skip_packages":["tmux"],"dotfiles_personal_enabled":false}' >/dev/null
[[ -L "$work/override/.vimrc" ]] || fail "override did not link vim"
[[ ! -e "$work/override/.tmux.conf" ]] || fail "exclusion not applied to explicit list"

# Unknown package fails; empty effective selection is a no-op.
mkdir -p "$work/unknown"
if run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["nope"],"dotfiles_personal_enabled":false}' >/dev/null 2>&1; then
  fail "unknown package did not fail"
fi
run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_stow_skip_packages":["vim"],"dotfiles_personal_enabled":false}' >/dev/null
[[ ! -e "$work/unknown/.vimrc" ]] || fail "empty selection linked a package"

# Conflicts preserve files and fail only in strict mode.
mkdir -p "$work/conflict"
printf 'local\n' > "$work/conflict/.vimrc"
run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_personal_enabled":false}' >/dev/null
[[ ! -L "$work/conflict/.vimrc" && "$(cat "$work/conflict/.vimrc")" == local ]] || fail "conflicting file overwritten"
if run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_personal_enabled":false,"dotfiles_stow_strict":true}' >/dev/null 2>&1; then
  fail "strict mode did not fail"
fi

# Work mode fails without the submodule and links only the work package when present.
mkdir -p "$work/work-missing"
if run_stow "$work/work-missing" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_work_enabled":true,"dotfiles_personal_enabled":false,"dotfiles_work_path":"'"$work"'/absent"}' >/dev/null 2>&1; then
  fail "work mode without the submodule did not fail"
fi
mkdir -p "$work/work-off" "$work/work-on" "$work/work-repo/work/.config/mise" \
  "$work/work-repo/work/ansible/packages" "$work/work-repo/vim"
touch "$work/work-repo/work/.config/mise/config.local.toml" \
  "$work/work-repo/work/ansible/packages/Brewfile" "$work/work-repo/work/README.md" \
  "$work/work-repo/vim/.vimrc"
printf 'ansible\nREADME.*\n' > "$work/work-repo/work/.stow-local-ignore"
run_stow "$work/work-off" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_personal_enabled":false}' >/dev/null
[[ ! -e "$work/work-off/.config/mise/config.local.toml" ]] || fail "work linked while disabled"
run_stow "$work/work-on" \
  -e '{"dotfiles_stow_packages":["vim"],"dotfiles_work_enabled":true}' \
  -e "dotfiles_repo_path=$work/work-repo" \
  -e "dotfiles_work_path=$work/work-repo/work" >/dev/null
[[ "$(readlink -f "$work/work-on/.config/mise/config.local.toml")" == "$work/work-repo/work/.config/mise/config.local.toml" ]] || fail "work mise overlay not linked"
[[ ! -e "$work/work-on/ansible" && ! -e "$work/work-on/README.md" ]] || fail "work provisioning files were linked"

if run_stow "$work/work-on" -e '{"dotfiles_work_enabled":true,"dotfiles_personal_enabled":true}' >/dev/null 2>&1; then
  fail "simultaneous personal and work settings did not fail"
fi

printf 'All Stow selection checks passed.\n'
