# Skill: Dev Workflow

## Purpose

This skill provides guidance for safely working with the dotfiles repository. It follows the Stow-based architecture where configuration packages are symlinked into `$HOME` and managed by Ansible.

## When to Use

Use this skill when:
- Making changes to any configuration package (`nvim/`, `tmux/`, `zsh/`, `git/`, etc.)
- Adding a new tool configuration
- Validating changes before committing
- Understanding the repository structure

## Quick Reference

| Task | Command |
|------|---------|
| Validate playbook | `ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check` |
| Validate all YAML | `python3 -c "..."` (see skill.yaml) |
| Test stow link | `stow <package-name>` |
| Re-run stow | `ansible-playbook ... --tags stow` |

## Architecture Overview

1. **Entry Point**: `ansible/site.yml` - orchestrates everything
2. **Stow Task**: `ansible/roles/stow/tasks/main.yml` - handles linking
3. **Profiles**: `ansible/profiles/*.yml` - define which packages to link
4. **Packages**: Top-level directories are Stow packages (not app code)

## Safe Change Workflow

1. Edit your package directory (e.g., `tmux/`, `nvim/`)
2. Test with `stow <package>` to validate the layout
3. Validate YAML: run the python script or ansible --syntax-check
4. Commit with a descriptive message referencing the change

## File Reference

- `/AGENTS.md` - Complete guide for all agents
- `/.github/copilot-instructions.md` - Original Copilot-specific version
- `/.clinerules` - Claude Code rules
