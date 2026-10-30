# Manual Installation Guide

Use this guide if you prefer to set up your environment step-by-step or if the automated setup is not compatible with your system.

## 📋 Prerequisites

### Package Managers
Ensure you have the following installed based on your OS:
- **Fedora**: `sudo dnf install stow git`
- **Ubuntu/Debian**: `sudo apt install stow git`
- **macOS**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` then `brew install stow git`

---

## 🛠️ Step-by-Step Setup

### 1. Clone the Repository
```sh
git clone https://github.com/gokul-t/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Symlink Configurations (GNU Stow)
Stow manages your dotfiles by creating symlinks. You can stow everything at once:
```sh
stow */
```
*This links zsh, tmux, nvim, git, bash, bin, code, ideavim, mise, npm, yazi, ghostty, lazygit, starship, claude, sesh, and vim.*

### 3. Install System Packages
Depending on your OS, install the required dependencies:

**Fedora:**
```sh
sudo dnf install $(grep -v '^#' ~/.dotfiles/dnf-packages.txt | xargs)
while read -r remote app; do
  case "$remote" in ""|\#*) continue ;; esac
  flatpak install --assumeyes "$remote" "$app"
done < ~/.dotfiles/flatpak-packages.txt
```

**macOS (using Brewfile):**
```sh
brew bundle --file ~/.dotfiles/Brewfile
```

### 4. Tool-Specific Configurations

#### Tmux Plugin Manager (TPM)
```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Then start tmux and press `prefix + I` to install plugins.
```

#### Neovim (LazyVim)
Simply open Neovim; LazyVim will bootstrap `lazy.nvim` and install plugins automatically:
```sh
nvim
```

#### IdeaVim (JetBrains)
```sh
git clone https://github.com/cufarvid/lazy-idea.git ~/.lazy-idea
```

#### Zsh Setup
1. **Oh My Zsh**: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
2. **Plugins**:
   ```sh
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   git clone https://github.com/MichaelAquilina/zsh-you-should-use ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
   ```
3. **User Config**: `touch ~/.zuserconfig.zsh`

#### Mise (Development Tools)
```sh
curl https://mise.run | sh
mise trust ~/.config/mise/config.toml
mise install
```

### 5. Final Touches
- **Fonts**: Install **MesloLGS Nerd Font**.
  ```sh
  curl -s https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh -o install.sh
  chmod u+x install.sh
  ./install.sh Meslo
  ```
- **Git Identity**:
  ```sh
  cp ~/.dotfiles/git/.identity.conf.example ~/.dotfiles/git/.identity.conf
  # Edit .identity.conf with your name and email.
  ```
- **Toshy (Linux)**: Follow [Toshy installation](https://github.com/RedBearAK/Toshy).

---

## 🔍 Troubleshooting

### Fonts not displaying correctly
- Verify that **MesloLGS Nerd Font** is installed and that your terminal (Ghostty) is explicitly configured to use it.

### Tmux plugins not loading
- Ensure TPM is at `~/.tmux/plugins/tpm`.
- Run `tmux source-file ~/.tmux.conf` and then press `prefix + I`.

### Neovim LSP/plugins not working
- Run `:checkhealth` inside Neovim.
- Ensure required language servers are installed via `:Mason`.

### Zsh plugins not working
- Verify the plugins exist in `~/.oh-my-zsh/custom/plugins/`.
- Restart your shell or run `source ~/.zshrc`.
