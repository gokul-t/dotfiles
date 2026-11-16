export AI_CODING_TOOL=claude

# worktrunk: default LLM commit message generation via Claude Code
export WORKTRUNK_COMMIT__GENERATION__COMMAND="MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model=haiku --tools='' --safe-mode --setting-sources='user' --system-prompt=''"

for env_file in ~/.config/zsh/env.d/*.zsh(N) ~/.config/zsh/user-env.d/*.zsh(N); do
 source "$env_file"
done

case "$OSTYPE" in
 darwin*)
   for env_file in ~/.config/zsh/darwin.env.d/*.zsh(N) ~/.config/zsh/user-darwin.env.d/*.zsh(N); do
     source "$env_file"
   done
   ;;
 linux*)
   for env_file in ~/.config/zsh/linux.env.d/*.zsh(N) ~/.config/zsh/user-linux.env.d/*.zsh(N); do
     source "$env_file"
   done
   ;;
esac

# Dedupe PATH entries (preserve order)
typeset -U path
