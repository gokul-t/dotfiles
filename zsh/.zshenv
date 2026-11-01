# Locale
export LANG="en_US.UTF-8"

# Base paths and tool roots (all shells)
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

setopt Null_glob
for env_file in ~/.config/zsh/env.d/*.zsh; do
  source "$env_file"
done
unsetopt null_glob

# Dedupe PATH entries (preserve order)
typeset -U path

