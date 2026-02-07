# Dotfiles

My .dotfiles repository - configuration files for development environment.

<!--toc:start-->
- [Dotfiles](#dotfiles)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
    - [Linux-Specific](#linux-specific)
    - [Mac-Specific](#mac-specific)
    - [Common Tools (All Platforms)](#common-tools-all-platforms)
    - [Development Tools](#development-tools)
  - [Installation Steps](#installation-steps)
  - [Usage](#usage)
    - [Quick Start Script](#quick-start-script)
    - [Tmux Key Bindings](#tmux-key-bindings)
    - [Zsh Features](#zsh-features)
  - [Key Configured Tools](#key-configured-tools)
    - [Neovim](#neovim)
    - [Tmux](#tmux)
    - [Alacritty](#alacritty)
    - [Shell Configuration](#shell-configuration)
  - [Troubleshooting](#troubleshooting)
    - [Fonts not displaying correctly](#fonts-not-displaying-correctly)
    - [Tmux plugins not loading](#tmux-plugins-not-loading)
    - [Neovim LSP/plugins not working](#neovim-lspplugins-not-working)
    - [Zsh plugins not working](#zsh-plugins-not-working)
  - [Notes](#notes)
<!--toc:end-->

## Overview

This repository contains configuration files for various applications and tools including Neovim, Tmux, Alacritty, Zsh, and more.

## Prerequisites

### Linux-Specific

- **Toshy** - Keyboard remapping for Linux (Mac-like shortcuts): [https://github.com/gokul-t/Toshy](https://github.com/gokul-t/Toshy)
- **GNU Stow** - Symlink farm manager for managing dotfiles

  ```sh
  sudo apt install stow  # For Debian/Ubuntu
  sudo dnf install stow  # For Fedora
  ```

### Mac-Specific

- To be documented

### Common Tools (All Platforms)

- **Git** - Version control
- **Neovim** - Text editor
- **Tmux** - Terminal multiplexer
- **Alacritty** - Terminal emulator
- **Tmux Plugin Manager (TPM)**: [https://github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm)
- **IdeaVim / Lazy-Idea** - Vim emulation for JetBrains IDEs

### Development Tools

- **SDKMAN** - SDK Manager for Java, Maven, Gradle, etc.
- **NVM** - Node Version Manager
- **pyenv** - Python version manager
- **Homebrew** (Linux/Mac) - Package manager
- **Rust/Cargo** - For Rust development

## Installation Steps

1. **Clone the Repository**

   ```sh
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Use GNU Stow to Symlink Configurations**

   Stow creates symlinks for your dotfiles. For each tool you want to configure:

   ```sh
   cd ~/.dotfiles
   stow alacritty  # Creates symlinks for Alacritty config
   stow zsh        # Creates symlinks for zsh config
   stow tmux       # Creates symlinks for tmux config
   stow nvim       # Creates symlinks for Neovim config
   stow git        # Creates symlinks for git config
   stow bash       # Creates symlinks for bash config
   stow bin        # Creates symlinks for custom scripts
   stow code       # Creates symlinks for VS Code config
   stow ideavim    # Creates symlinks for IdeaVim config
   ```

   Or stow all at once:

   ```sh
   stow */
   ```

3. **Install Fonts**

   Download and install **MesloLGS Nerd Font**:

   ```sh
   # Download from: https://github.com/ryanoasis/nerd-fonts/releases
   
   # For Linux:
   mkdir -p ~/.local/share/fonts
   cp MesloLGS*.ttf ~/.local/share/fonts/
   fc-cache -fv
   ```

4. **Set Up Tmux Plugin Manager**

   ```sh
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

   Then start tmux and install plugins:

   ```sh
   tmux
   # Press prefix + I (default prefix is Ctrl+b) to install plugins
   ```

5. **Set Up Neovim**

   Open Neovim and LazyVim will automatically install all plugins:

   ```sh
   nvim
   ```

   LazyVim will bootstrap `lazy.nvim` and install all configured plugins automatically.

6. **Set Up IdeaVim (for JetBrains IDEs)**

   ```sh
   git clone https://github.com/cufarvid/lazy-idea.git ~/.lazy-idea
   ```

   The `.ideavimrc` file will source this configuration automatically.

7. **Configure Git Identity**

   Copy the example identity file and edit with your details:

   ```sh
   cp ~/.dotfiles/git/.identity.conf.example ~/.dotfiles/git/.identity.conf
   # Edit the file with your name, email, and GPG key
   ```

8. **Set Up Shell Environment**

   For **Zsh** users:
   - Install Oh My Zsh:

     ```sh
     sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
     ```

   - Install Zsh plugins:

     ```sh
     git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
     git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
     git clone https://github.com/MichaelAquilina/zsh-you-should-use ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
     ```

   - Create user-specific config file (not tracked in git):

     ```sh
     touch ~/.zuserconfig.zsh
     ```

9. **Install Development Tools**

   - **SDKMAN** (Java, Maven, Gradle):

     ```sh
     curl -s "https://get.sdkman.io" | bash
     ```

   - **NVM** (Node Version Manager):

     ```sh
     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
     ```

   - **pyenv** (Python version manager):

     ```sh
     curl https://pyenv.run | bash
     ```

   - **Homebrew** (Linux):

     ```sh
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```

10. **Linux-Specific: Install Toshy**

    For keyboard remapping on Linux (Mac-like shortcuts):

    ```sh
    # Follow instructions at: https://github.com/gokul-t/Toshy
    ```

## Usage

### Quick Start Script

Use the `syscfg` script to open a tmux session with Neovim in the dotfiles directory:

```sh
~/bin/syscfg
```

### Tmux Key Bindings

- `prefix + I` - Install tmux plugins
- `prefix + r` - Reload tmux configuration
- `prefix + h` - Split window horizontally
- `prefix + v` - Split window vertically
- `Ctrl+h/j/k/l` - Navigate between tmux panes and vim splits (via vim-tmux-navigator)

### Zsh Features

- Auto-activation of Python virtual environments when entering directories with `.venv`
- Git integration with status in prompt
- Docker/Podman alias (docker → podman)
- History sharing across sessions
- Vi mode with `V` to edit command in Neovim

## Key Configured Tools

### Neovim

- **LazyVim** distribution with extensive language support
- Languages configured: Python, Java, Terraform, YAML, TOML, Markdown
- Plugins include: Copilot, DAP debugging, Treesitter, LSP support
- Theme: Tokyo Night

### Tmux

- Theme: Tokyo Night Moon
- Plugins: vim-tmux-navigator, tmux-yank, tmux-resurrect, tmux-continuum
- Auto-restore sessions on restart

### Alacritty

- Theme: Tokyo Night
- Font: MesloLGS Nerd Font (size 12)
- Custom keybindings for Alt-based word navigation

### Shell Configuration

- **Zsh** with Oh My Zsh framework
- Theme: robbyrussell
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, you-should-use, docker, kubectl, maven, python, pyenv, z

## Troubleshooting

### Fonts not displaying correctly

- Ensure MesloLGS Nerd Font is installed and font cache is refreshed
- Verify Alacritty configuration points to the correct font family

### Tmux plugins not loading

- Ensure TPM is installed: `~/.tmux/plugins/tpm`
- Press `prefix + I` to install plugins
- Check tmux configuration: `tmux source-file ~/.tmux.conf`

### Neovim LSP/plugins not working

- Open Neovim and check `:Lazy` for plugin status
- Run `:checkhealth` to diagnose issues
- Ensure required language servers are installed via Mason

### Zsh plugins not working

- Verify Oh My Zsh is installed
- Check that plugin directories exist in `~/.oh-my-zsh/custom/plugins/`
- Reload shell configuration: `source ~/.zshrc`

## Notes

- User-specific files (like `.zuserconfig.zsh` and `git/.identity.conf`) are git-ignored
- Use Stow to manage symlinks - avoid manually copying files
- After major updates, restart your terminal/applications to apply changes
- Refer to individual tool documentation for advanced customization
