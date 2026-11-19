# imagemagick-full
export PATH="/opt/homebrew/opt/imagemagick-full/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/imagemagick-full/lib"
export CPPFLAGS="-I/opt/homebrew/opt/imagemagick-full/include"

export PATH="$HOME/.ccli/bin:$PATH"

export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"

# XDG config dir (lazygit and other CLI tools resolve their config here)
export XDG_CONFIG_HOME="$HOME/.config"

# Added by Toolbox App
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
