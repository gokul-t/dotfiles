# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs

if [[ $OSTYPE == "darwin"* ]]; then
elif [[ $OSTYPE == "linux-gnu" ]]; then 
  # Added by Toolbox App
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
else 
fi
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
