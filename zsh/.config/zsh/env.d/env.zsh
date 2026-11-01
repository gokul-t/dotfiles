# Check and source OS-specific config files if they exist
if [[ "$OSTYPE" == darwin* ]]; then
  [[ -f ~/.config/zsh/env.d/macos.env ]] && source ~/.config/zsh/env.d/macos.env
elif [[ "$OSTYPE" == linux* ]]; then
  [[ -f ~/.config/zsh/env.d/linux.env ]] && source ~/.config/zsh/env.d/linux.env
fi

# opencode
export PATH=/home/gokult/.opencode/bin:$PATH

export CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1
export CLAUDE_CODE_MAX_CONTEXT_TOKENS=8192
