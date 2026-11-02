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
