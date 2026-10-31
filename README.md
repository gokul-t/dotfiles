# Dotfiles

My .dotfiles repository - configuration files for a highly customized development environment.

## 🚀 Quick Start

Depending on your preference and system, choose one of the following paths:

- **[Automated Setup](INSTALL_AUTOMATED.md)**: Recommended. A one-command bootstrap using Ansible to handle package installation and configuration. (Supports Workstation and Minimal Server profiles).
- **[Manual Setup](INSTALL_MANUAL.md)**: For power users who prefer granular control or are on unsupported platforms.

---

## 🛠️ Key Configured Tools

This environment is centered around a cohesive, keyboard-centric workflow:

### 💻 Editor & Terminal
- **Neovim**: Powered by **LazyVim** with full LSP support for Python, Java, Terraform, YAML, and TOML.
- **Tmux**: Terminal multiplexer with session persistence and a shared navigation experience with Neovim.
- **Ghostty**: A high-performance terminal emulator with custom keybindings for seamless navigation.

### 🐚 Shell & Workflow
- **Zsh**: Enhanced with Oh My Zsh, auto-suggestions, and syntax highlighting.
- **Sesh**: A powerful session manager for Tmux to organize projects and workspaces.
- **Mise**: Tool version manager for Java, Node.js, Python, and Rust.
- **Stow**: Used to manage the symlink farm from this repository to the home directory.

### 📦 CLI Utilities
- **fzf** & **rg (ripgrep)**: For lightning-fast searching and filtering.
- **zoxide**: A smarter `cd` command.
- **yazi** & **lazygit**: TUI interfaces for file and git management.
- **Starship**: A cross-shell customizable prompt.

---

## ⌨️ Usage & Key Bindings

### Tmux Navigation
- `prefix + I` : Install tmux plugins
- `prefix + r` : Reload tmux configuration
- `prefix + h/v` : Split window horizontally/vertically
- `Ctrl + h/j/k/l` : Seamless navigation between tmux panes and Neovim splits

### Sesh Session Management
- `prefix + T` : Open the session picker (the heart of the workflow)
- `prefix + W` : Pick a window in the current session
- `prefix + L` : Switch to the last session

### Zsh Features
- **Auto-venv**: Automatic Python virtual environment activation.
- **Vi-Mode**: Use `V` to edit the current command line in Neovim.

---

## ❓ Troubleshooting & Support

For common issues regarding fonts, LSP setup, or plugin loading, please refer to the **[Manual Installation Guide](INSTALL_MANUAL.md)** under the Troubleshooting section.
