########################################
# NVM (login shells / scripts)
########################################

[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

########################################
# SDKMAN (Java, Maven, Gradle, etc.)
########################################

[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

########################################
# Java & Maven (SDKMAN managed)
########################################

# JAVA_HOME usually set by SDKMAN, fallback for safety
if command -v java >/dev/null 2>&1; then
  export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home 2>/dev/null)}"
fi

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
