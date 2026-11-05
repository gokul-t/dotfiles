# Copilot Instructions for this dotfiles repository

> **See [AGENTS.md](../AGENTS.md) for the complete and canonical agent instructions.**

This file is kept for GitHub Copilot compatibility and simply points to the shared instructions.

## Quick reference

- **Repository**: GNU Stow-based dotfiles collection (NOT application code).
- **Validate**: `ansible-playbook -i ansible/inventory.ini ansible/site.yml --syntax-check`
- **Test**: `stow <package-name>` / `bash ansible/containers/test-stow.sh`

## What to avoid

- Do not add application source code to config packages.
- Do not invent new repo-wide test infrastructure.
- Do not create ad hoc install scripts.

For full details, see [AGENTS.md](../AGENTS.md).
