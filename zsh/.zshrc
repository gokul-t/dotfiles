# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

setopt null_glob
for config_file in ~/.config/zsh/conf.d/*.zsh; do
  source "$config_file"
done
unsetopt null_glob

source $ZSH/oh-my-zsh.sh
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

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform


############################
# Pyenv
############################

if command -v pyenv 1>/dev/null 2>&1; then
 eval "$(pyenv init -)"
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
