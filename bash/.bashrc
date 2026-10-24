# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific environment
export LANG="en_US.UTF-8"

if [[ -d "$HOME/bin" && ":$PATH:" != *":$HOME/bin:"* ]]; then
  PATH="$HOME/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "$HOME/.cargo/bin" && ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
  PATH="$HOME/.cargo/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [[ -d "$HOME/.bashrc.d" ]]; then
  for rc in "$HOME"/.bashrc.d/*; do
    [[ -f "$rc" ]] && . "$rc"
  done
fi
unset rc

for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$brew" ]]; then
    eval "$("$brew" shellenv)"
    break
  fi
done

if command -v podman >/dev/null 2>&1; then
  alias docker="podman"
fi

if [[ -n "$SSH_CONNECTION" ]]; then
  export EDITOR="vim"
  export VISUAL="vim"
else
  export EDITOR="nvim"
  export VISUAL="nvim"
fi

alias vi="vim"
alias vim="vim"
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."

if command -v terraform >/dev/null 2>&1; then
  complete -C "$(command -v terraform)" terraform
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
