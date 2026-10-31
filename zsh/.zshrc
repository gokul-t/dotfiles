# PATH is managed in ~/.zshenv

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"  # replaced by starship below when available

# Force 256color and True Color support across Tmux/Vim
export COLORTERM="truecolor"

# Plugins and other settings live in ~/.config/zsh/conf.d, loaded before Oh My Zsh
setopt null_glob
for config_file in ~/.config/zsh/conf.d/*.zsh; do
  source "$config_file"
done
unsetopt null_glob

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi
# export MANPATH="/usr/local/man:$MANPATH"
# user scripts and customizations
# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR="vim"
  export VISUAL="vim"
else
  export EDITOR="nvim"
  export VISUAL="nvim"
fi

# Bind 'V' in normal mode to open the command line in nvim
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'V' edit-command-line

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

if command -v podman >/dev/null; then
  alias docker="podman"
fi

############################
# Terraform
############################

if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi


# Auto-activate venv when changing directories
function auto_venv_activate() {
 local venv_path="./.venv/bin/activate"
 if [[ -f "$venv_path" ]]; then
  if [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
   source "$venv_path" > /dev/null 2>&1
   echo "Activated: $(basename $VIRTUAL_ENV)"
  fi
 elif [[ -n "$VIRTUAL_ENV" ]]; then
  # Deactivate if leaving a venv directory
  parentdir="$(dirname "$VIRTUAL_ENV")"
  if [[ "$PWD"/ != "$parentdir"/* ]]; then
   deactivate > /dev/null 2>&1
   echo "Deactivated: $(basename $parentdir)"
  fi
 fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd auto_venv_activate
auto_venv_activate # Run once for the initial directory

############################
# History
############################

HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

############################
# Prompt Customization (Optional)
############################

# Show command execution time if > 5s
export REPORTTIME=5

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  ZSH_THEME=""
  eval "$(starship init zsh)"
fi

function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}
