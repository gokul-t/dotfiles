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
  - [Automated Setup with Ansible](#automated-setup-with-ansible)
    - [One-Command Setup](#one-command-setup)
  - [Usage](#usage)
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

- **Toshy** - Optional keyboard remapping for Linux (Mac-like shortcuts): [https://github.com/RedBearAK/Toshy](https://github.com/RedBearAK/Toshy)
- **GNU Stow** - Symlink farm manager for managing dotfiles
- **DNF Packages** - List of Fedora dependencies in `dnf-packages.txt`
- **Flatpak Apps** - List of Flatpak applications in `flatpak-packages.txt`

  ```sh
  sudo dnf install stow  # For Fedora
  sudo apt install stow  # For Debian/Ubuntu
  ```

  Install the listed Fedora packages and Flatpak apps:

  ```sh
  sudo dnf install $(grep -v '^#' ~/.dotfiles/dnf-packages.txt | xargs)
  while read -r remote app; do
    case "$remote" in ""|\#*) continue ;; esac
    flatpak install --assumeyes "$remote" "$app"
  done < ~/.dotfiles/flatpak-packages.txt
  ```

### Mac-Specific

- **Homebrew** - Package manager

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

- **GNU Stow** - Symlink farm manager for managing dotfiles

  ```sh
  brew install stow
  ```

### Common Tools (All Platforms)

- **Git** - Version control
- **Neovim** - Text editor
- **Tmux** - Terminal multiplexer
- **Alacritty / Ghostty** - Terminal emulators
- **Tmux Plugin Manager (TPM)**: [https://github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm)
- **IdeaVim / Lazy-Idea** - Vim emulation for JetBrains IDEs
- **sesh** - Terminal session manager integrated with Tmux
- zoxide - A smarter cd command, inspired by z and autojump.
- fzf - A general-purpose command-line fuzzy finder.
- rg (ripgrep) - A line-oriented search tool that recursively searches your current directory for a regex pattern.
- yazi - tui file manager written in Rust.
- lazygit - Simple git tui.
- starship - The customizable prompt for any shell.

### Development Tools

- **mise** - Manages Java, Maven, Node.js, Python, and other development tool versions from project configuration.
- **Homebrew** (Linux/Mac) - Package manager
- **Rust/Cargo** - Managed by mise for Rust development

## Installation Steps

1. **Clone the Repository**

   ```sh
   git clone https://github.com/gokul-t/dotfiles.git ~/.dotfiles
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
   stow mise       # Creates symlinks for mise config
   stow npm        # Creates symlinks for npm config
   stow yazi       # Creates symlinks for yazi config
   stow ghostty    # Creates symlinks for ghostty config
   stow lazygit    # Creates symlinks for lazygit config
   stow starship   # Creates symlinks for starship config
   stow claude     # Creates symlinks for Claude config
   stow sesh       # Creates symlinks for sesh config
   stow vim        # Creates symlinks for vim config  
   ```

   Or stow all at once:

   ```sh
   stow */
   ```

3. **Linux-Specific: Install Fonts**

   Download and install **MesloLGS Nerd Font**:

   ```sh
   # Download from: https://github.com/ryanoasis/nerd-fonts/releases

   # For Linux:
   mkdir -p ~/.local/share/fonts
   cp MesloLGS*.ttf ~/.local/share/fonts/
   fc-cache -fv
   # or
   curl -s https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh -o install.sh
   chmod u+x install.sh
   ./install.sh Meslo
   ```

4. **Install Packages via Brewfile**

  Installs CLI tools, casks, and VS Code extensions listed in `Brewfile`:

    ```sh
    brew bundle --file ~/.dotfiles/Brewfile
    ```

1. **Set Up Tmux Plugin Manager**

   ```sh
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

   Then start tmux and install plugins:

   ```sh
   tmux
   # Press prefix + I (default prefix is Ctrl+b) to install plugins
   ```

2. **Set Up Neovim**

   Open Neovim and LazyVim will automatically install all plugins:

   ```sh
   nvim
   ```

   LazyVim will bootstrap `lazy.nvim` and install all configured plugins automatically.

3. **Set Up IdeaVim (for JetBrains IDEs)**

   ```sh
   git clone https://github.com/cufarvid/lazy-idea.git ~/.lazy-idea
   ```

   The `.ideavimrc` file will source this configuration automatically.

4. **Configure Git Identity**

   Copy the example identity file and edit with your details:

   ```sh
   cp ~/.dotfiles/git/.identity.conf.example ~/.dotfiles/git/.identity.conf
   # Edit the file with your name, email, and GPG key
   ```

5. **Set Up Shell Environment**

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

6. **Install Development Tools**

    - **Homebrew** (Linux):

        ```sh
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ```

    - **mise** (config at `~/.config/mise/config.toml`; Ansible installs it automatically):

        ```sh
        curl https://mise.run | sh
        mise trust ~/.config/mise/config.toml
        mise install
        ```

      Project-specific runtimes are declared in each repository's `mise.toml`.
      Run `mise install` after cloning a project to install its pinned tools.

7. **Linux-Specific: Install Toshy**

    For keyboard remapping on Linux (Mac-like shortcuts):

    ```sh
    # Follow instructions at: https://github.com/RedBearAK/Toshy
    ```

## Automated Setup with Ansible

### One-Command Setup

Run this from a terminal as your regular user to bootstrap and run the Ansible
setup:

```sh
curl -fsSL https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh | bash
```

The script supports Fedora, Ubuntu/WSL, and macOS. It installs missing Ansible
and Git using DNF or APT on Linux; on macOS, install Homebrew first, and the
script uses it to install missing tools. It clones this repository to
`~/.dotfiles` if needed, reuses an existing valid checkout without updating it,
then runs the playbook. Linux setup prompts for the become password when
required. On WSL, it disables Snap app installation because Snap may require
systemd. The playbook installs packages and links configurations, so review the
[bootstrap script](ansible/bootstrap.sh) and the playbook before running it.
If Rust installation hits the known [Rustup 1.29.2 SIGILL bug](https://github.com/rust-lang/rustup/issues/5160),
the setup warns and continues with the other tools; retry Rust installation once
Rustup 1.29.3 or newer is available.

On Fedora and non-WSL Ubuntu, if Toshy is not already installed, the script
offers to install it. Toshy remaps keyboard shortcuts to provide a macOS-like
experience and changes keyboard behavior. It needs a supported Fedora/Ubuntu
system, admin access, and a compatible desktop/session (Wayland supports only
certain desktops; GNOME requires a compatible extension). Use a fully updated
system. The prompt explains these requirements before asking; Toshy's installer
also checks system readiness and offers its own confirmation/configuration
choices. See Toshy's [requirements](https://github.com/RedBearAK/Toshy#requirements)
and [supported desktops](https://github.com/RedBearAK/Toshy#currently-working-desktop-environments-or-window-managers).
Toshy is not offered on WSL or macOS.

To inspect the downloaded script before executing it:

```sh
curl -fsSLo /tmp/dotfiles-bootstrap.sh https://raw.githubusercontent.com/gokul-t/dotfiles/main/ansible/bootstrap.sh
less /tmp/dotfiles-bootstrap.sh
bash /tmp/dotfiles-bootstrap.sh
```

### Manual Setup

The local Ansible playbook installs platform packages, links every top-level
Stow package (excluding the `ansible` automation directory), and sets up shell
plugins and development tools. It also sets the account running the playbook
to use Zsh as its login shell if it is not already configured. Add or remove
Fedora packages in `dnf-packages.txt` or Ubuntu packages in
`ubuntu-packages.txt`; no Ansible variable list needs updating. Fedora package
repositories for VS Code, Chrome, Terraform, sesh, Starship, and Ghostty are
configured by the playbook; Starship and Ghostty use Fedora COPR repositories.
Flatpak apps are installed system-wide on Fedora. Ubuntu uses Snap
packages for apps unavailable in its APT repositories; Snap app installation can
be disabled with `-e dotfiles_install_snap_apps=false`.

To run the playbook manually, install Ansible and Git, then clone this repository:

```sh
# Fedora
sudo dnf install ansible-core git

# Ubuntu / Ubuntu on WSL
sudo apt update
sudo apt install ansible-core git

# macOS: install Homebrew first if it is not already installed
brew install ansible git

git clone https://github.com/gokul-t/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Run the playbook on Fedora with privilege escalation:

```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass
```

To test Linux provisioning without changing your workstation, build and run
the disposable Ubuntu or Fedora containers from the repository root:

```sh
docker build -f ansible/containers/ubuntu.Dockerfile -t dotfiles-test:ubuntu .
docker run --rm dotfiles-test:ubuntu

docker build -f ansible/containers/fedora.Dockerfile -t dotfiles-test:fedora .
docker run --rm dotfiles-test:fedora
```

The containers run Ansible as root and use a separate `/tmp` Stow target, so no
become password is needed and dotfiles are not linked over the container's home
files. The container arguments disable Flatpak/Snap installation and skip
desktop applications, services, or packages unavailable in the base image.
These are container-test settings only; the normal workstation playbook still
uses the platform package manifests and installs Flatpak or Snap apps.

On macOS, run without privilege escalation:

```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

On Ubuntu (including Ubuntu on WSL), run from the Ubuntu shell:

```sh
ansible-playbook -i ansible/inventory.ini ansible/site.yml --ask-become-pass
```

The Ubuntu APT manifest installs available equivalents of the Fedora tools;
packages unavailable in Ubuntu repositories and selected desktop applications
are installed from `ubuntu-snap-packages.txt`. Snap installation can be
disabled for environments such as WSL where snapd is unavailable. Go is
managed by mise and used to install LazyGit with `go install`. Sesh is downloaded
from its latest upstream GitHub release and checked against the release asset
SHA-256 digest; Google Chrome uses Google's signed APT repository on x86_64.

GitHub Actions checks Ansible/YAML syntax on every push and pull request. Full
Fedora 44 and Ubuntu 24.04 container provisioning tests run weekly and can also
be started manually from the repository's **Actions → Ansible → Run workflow**
page. Each test provisions twice and checks that the second run reports no
changes.

Stow never overwrites existing files. If a package conflicts with files already
in your home directory, that package is skipped with a warning and provisioning
continues for the other packages. Review the conflict details, back up or
reconcile the existing files, then rerun setup to link the skipped package.
The playbook leaves Git identity and default-shell selection to you. Configure
Git identity using the manual steps above. On Linux, use the optional Toshy
prompt in the one-command setup or follow its
[project instructions](https://github.com/RedBearAK/Toshy).

## Usage

### Tmux Key Bindings

- `prefix + I` - Install tmux plugins
- `prefix + r` - Reload tmux configuration
- `prefix + h` - Split window horizontally
- `prefix + v` - Split window vertically
- `Ctrl+h/j/k/l` - Navigate between tmux panes and vim splits (via vim-tmux-navigator)

### Sesh Session Manager

Sesh manages Tmux sessions and windows. Its configuration is stored at
`~/.config/sesh/sesh.toml` and is included in this repository's `sesh` Stow
package. The config defines Dotfiles, Notes, and Downloads sessions, plus
wildcard sessions for repositories under `~/Developer/repos/*/*`. Sessions
can start configured windows such as Neovim, Git, Copilot, Lazygit, and Yazi.

Install sesh and its picker dependencies (`fzf`, `zoxide`, and `fd`). On macOS,
these are included in the `Brewfile`; on other systems, install them with your
package manager. Then run `stow sesh` to link its configuration. The Fedora
Ansible workflow installs the Zsh completion system-wide at
`/usr/local/share/zsh/site-functions/_sesh`. Homebrew generates and installs
the completion automatically on macOS.

For a manual Linux installation, generate and install the completion with:

```sh
sesh completion zsh > _sesh
sudo mkdir -p /usr/local/share/zsh/site-functions
sudo cp _sesh /usr/local/share/zsh/site-functions/
```

With the default Tmux prefix (`Ctrl+b`), use:

- `prefix + T` - Open the session picker. Use `Ctrl+a` for all sessions,
  `Ctrl+t` for Tmux sessions, `Ctrl+g` for configured sessions, `Ctrl+x` for
  zoxide directories, or `Ctrl+f` to find directories. `Ctrl+d` kills the
  selected Tmux session.
- `prefix + W` - Pick a window in the current session.
- `prefix + L` - Switch to the last session.
- `prefix + 9` - Connect to the root session for the current directory.

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

- Theme: Minimal Theme
- Plugins: vim-tmux-navigator, tmux-yank, tmux-resurrect, tmux-continuum
- Auto-restore sessions on restart

### Alacritty

- Theme: Tokyo Night
- Font: MesloLGS Nerd Font (size 12)
- Custom keybindings for Alt-based word navigation

### Shell Configuration

- **Zsh** with Oh My Zsh framework
- Theme: robbyrussell
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, you-should-use, docker, kubectl, maven, python, z

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

- User-specific files (like `git/.identity.conf`) are git-ignored
- Use Stow to manage symlinks - avoid manually copying files
- After major updates, restart your terminal/applications to apply changes
- Refer to individual tool documentation for advanced customization
