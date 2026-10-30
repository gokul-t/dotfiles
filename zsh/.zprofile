########################################
# ~/.zprofile
# Login shell configuration
########################################

########################################
# Homebrew (macOS only)
########################################
# Uncomment if you use Homebrew and command not found issues occur
# eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
# eval "$(/usr/local/bin/brew shellenv)"      # Intel Mac

# Reuse a single ssh-agent across login shells
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
ssh-add -l >/dev/null 2>&1
if [[ $? -eq 2 ]]; then
  mkdir -p "$HOME/.ssh"
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)" >/dev/null
fi

# GPG
export GPG_TTY=$(tty)
