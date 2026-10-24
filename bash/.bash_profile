# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs

if [[ $OSTYPE == "darwin"* ]]; then
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
elif [[ $OSTYPE == "linux-gnu" ]]; then
  # Added by Toolbox App
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
fi
