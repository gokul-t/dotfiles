#!/usr/bin/env bash
# Exercises Stow package selection against disposable targets; never touches $HOME.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

work="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$work" "$repo_root/zz-undeclared"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

run_stow() {
  local target="$1"; shift
  ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags stow \
    -e "dotfiles_stow_target=$target" "$@"
}

# Default selection links shared packages only, not private or undeclared directories.
mkdir -p "$work/default" "$repo_root/zz-undeclared/.config"
touch "$repo_root/zz-undeclared/.config/undeclared"
default_args=(-e '{"dotfiles_stow_packages":["vim","tmux"]}')
run_stow "$work/default" "${default_args[@]}" | tee "$work/first.log"
grep -Eq 'changed=[1-9]' "$work/first.log" || fail "first run did not report changes"
[[ "$(readlink -f "$work/default/.vimrc")" == "$repo_root/vim/.vimrc" ]] || fail ".vimrc not linked"
[[ "$(readlink -f "$work/default/.tmux.conf")" == "$repo_root/tmux/.tmux.conf" ]] || fail ".tmux.conf not linked"
[[ ! -e "$work/default/.identity.conf" ]] || fail "private overlay identity linked by default"
[[ ! -e "$work/default/.config/undeclared" ]] || fail "undeclared package was linked"
run_stow "$work/default" "${default_args[@]}" | tee "$work/second.log"
grep -Eq 'changed=0' "$work/second.log" || fail "second run reported changes"

# Explicit personal selection links the optional overlay when it is available.
if [[ -f "$repo_root/personal/.identity.conf" && -f "$repo_root/personal/.config/zsh/user-env.d/env.zsh" ]]; then
  mkdir -p "$work/personal"
  run_stow "$work/personal" \
    -e '{"dotfiles_stow_packages":["vim","tmux"],"dotfiles_private_enabled":true,"dotfiles_private_profile":"personal"}' \
    -e dotfiles_profile=personal >/dev/null
  [[ "$(readlink -f "$work/personal/.identity.conf")" == "$repo_root/personal/.identity.conf" ]] || fail "explicit personal overlay not linked"
fi

# Explicit override and exclusions.
mkdir -p "$work/override"
run_stow "$work/override" -e '{"dotfiles_stow_packages":["vim","tmux"],"dotfiles_stow_skip_packages":["tmux"],"dotfiles_private_enabled":false}' >/dev/null
[[ -L "$work/override/.vimrc" ]] || fail "override did not link vim"
[[ ! -e "$work/override/.tmux.conf" ]] || fail "exclusion not applied to explicit list"

# Unknown package fails; empty effective selection is a no-op.
mkdir -p "$work/unknown"
if run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["nope"],"dotfiles_private_enabled":false}' >/dev/null 2>&1; then
  fail "unknown package did not fail"
fi
run_stow "$work/unknown" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_stow_skip_packages":["vim"],"dotfiles_private_enabled":false}' >/dev/null
[[ ! -e "$work/unknown/.vimrc" ]] || fail "empty selection linked a package"

# Conflicts preserve files and fail only in strict mode.
mkdir -p "$work/conflict"
printf 'local\n' > "$work/conflict/.vimrc"
run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_private_enabled":false}' >/dev/null
[[ ! -L "$work/conflict/.vimrc" && "$(cat "$work/conflict/.vimrc")" == local ]] || fail "conflicting file overwritten"
if run_stow "$work/conflict" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_private_enabled":false,"dotfiles_stow_strict":true}' >/dev/null 2>&1; then
  fail "strict mode did not fail"
fi

# Private overlay mode fails without the submodule and links only the overlay package when present.
mkdir -p "$work/work-missing"
missing_path="${work}/absent"
if run_stow "$work/work-missing" \
  -e "{\"dotfiles_stow_packages\":[\"vim\"],\"dotfiles_private_enabled\":true,\"dotfiles_private_profile\":\"work\",\"dotfiles_private_path\":\"${missing_path}\"}" \
  -e dotfiles_profile=work >/dev/null 2>&1; then
  fail "private overlay mode without the submodule did not fail"
fi
mkdir -p "$work/work-off" "$work/work-on" "$work/work-repo/work/.config/mise" \
  "$work/work-repo/work/ansible/packages" "$work/work-repo/vim"
touch "$work/work-repo/work/.config/mise/config.local.toml" \
  "$work/work-repo/work/ansible/packages/Brewfile" "$work/work-repo/work/README.md" \
  "$work/work-repo/vim/.vimrc"
printf 'ansible\nREADME.*\n' > "$work/work-repo/work/.stow-local-ignore"
run_stow "$work/work-off" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_private_enabled":false}' -e dotfiles_profile=work >/dev/null
[[ ! -e "$work/work-off/.config/mise/config.local.toml" ]] || fail "work linked while disabled"
run_stow "$work/work-on" \
  -e '{"dotfiles_stow_packages":["vim"],"dotfiles_private_enabled":true,"dotfiles_private_profile":"work"}' \
  -e "dotfiles_repo_path=$work/work-repo" \
  -e "dotfiles_private_path=$work/work-repo/work" \
  -e dotfiles_profile=work >/dev/null
[[ "$(readlink -f "$work/work-on/.config/mise/config.local.toml")" == "$work/work-repo/work/.config/mise/config.local.toml" ]] || fail "work mise overlay not linked"
[[ ! -e "$work/work-on/ansible" && ! -e "$work/work-on/README.md" ]] || fail "work provisioning files were linked"

if run_stow "$work/server-private" -e '{"dotfiles_stow_packages":["vim"],"dotfiles_private_enabled":true}' -e dotfiles_profile=server >/dev/null 2>&1; then
  fail "private overlay with the server profile did not fail"
fi

printf 'All Stow selection checks passed.\n'
