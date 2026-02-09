# Locale
export LANG="en_US.UTF-8"

# Base paths and tool roots (all shells)
export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export SDKMAN_DIR="$HOME/.sdkman"

[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

MAVEN_HOME="$HOME/.sdkman/candidates/maven/current"
[[ -d "$MAVEN_HOME/bin" ]] && export PATH="$MAVEN_HOME/bin:$PATH"

if [[ $OSTYPE == "darwin"* ]]; then
	[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
elif [[ $OSTYPE == "linux-gnu" ]]; then
	# Added by Toolbox App
	[[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]] && export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
fi

# Dedupe PATH entries (preserve order)
typeset -U path

