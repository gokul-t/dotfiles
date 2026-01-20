

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"

if [[ $OSTYPE == "darwin"* ]]; then
elif [[ $OSTYPE == "linux-gnu" ]]; then 
  # Added by Toolbox App
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
else 
fi

############################
# Pyenv
############################

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
 eval "$(pyenv init --path)"
fi
