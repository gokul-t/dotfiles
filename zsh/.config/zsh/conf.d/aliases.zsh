
############################
# Vim
############################

alias vi="vim"
alias vim="vim"

############################
# Quality of Life Aliases
############################

alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias inv='nvim $(fzf -m --tmux --preview="bat --color=always {}")'
if command -v zoxide >/dev/null 2>&1; then
  alias cd="z"
fi
