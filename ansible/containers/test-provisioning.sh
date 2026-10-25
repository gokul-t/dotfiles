#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
extra_vars="${DOTFILES_ANSIBLE_EXTRA_VARS:?DOTFILES_ANSIBLE_EXTRA_VARS must be set}"
first_run_log=/tmp/ansible-first-run.log
second_run_log=/tmp/ansible-second-run.log

cd "$repo_root"

ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -e "$extra_vars" | tee "$first_run_log"

ansible-playbook -i ansible/inventory.ini ansible/site.yml \
  -e "$extra_vars" | tee "$second_run_log"

grep -Eq 'localhost[[:space:]]*:[[:space:]]+ok=[0-9]+[[:space:]]+changed=0([[:space:]]|$)' \
  "$second_run_log"
