# Check and source OS-specific config files if they exist
if [[ "$OSTYPE" == darwin* ]]; then
  [[ -f ~/.config/zsh/env.d/macos.env ]] && source ~/.config/zsh/env.d/macos.env
elif [[ "$OSTYPE" == linux* ]]; then
  [[ -f ~/.config/zsh/env.d/linux.env ]] && source ~/.config/zsh/env.d/linux.env
fi
