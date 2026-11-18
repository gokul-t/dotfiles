# Set up fzf key bindings and fuzzy completion
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

n() {
    echo "- $(date '+%Y-%m-%d %H:%M') | $*" >> ~/Documents/notes/inbox.md
}
