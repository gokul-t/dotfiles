########################################
# ~/.zprofile
# Login shell configuration
########################################

# Locale
export LANG="en_US.UTF-8"

########################################
# Homebrew (macOS only)
########################################
# Uncomment if you use Homebrew and command not found issues occur
# eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
# eval "$(/usr/local/bin/brew shellenv)"      # Intel Mac

########################################
# pyenv (MUST be here)
########################################

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

########################################
# NVM (login shells / scripts)
########################################

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

########################################
# SDKMAN (Java, Maven, Gradle, etc.)
########################################

export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

########################################
# Java & Maven (SDKMAN managed)
########################################

# JAVA_HOME usually set by SDKMAN, fallback for safety
if command -v java >/dev/null 2>&1; then
  export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home 2>/dev/null)}"
fi

export MAVEN_HOME="$HOME/.sdkman/candidates/maven/current"
export PATH="$MAVEN_HOME/bin:$PATH"

########################################
# User binaries
########################################

export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

########################################
if [[ $OSTYPE == "darwin"* ]]; then
elif [[ $OSTYPE == "linux-gnu" ]]; then
  # Added by Toolbox App
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
else
fi
