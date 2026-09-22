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

# Start ssh-agent if not running
if [[ -z "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)" >/dev/null
fi

# pyenv (login shells)
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# GPG
export GPG_TTY=$(tty)
