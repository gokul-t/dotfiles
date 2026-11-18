############################
# Vi Mode (Hybrid Emacs + Vi)
############################
# Enable vi editing mode (vim-style modal editing) with emacs-compatible
# editing conveniences. The Oh My Zsh 'vi-mode' plugin supplies the vi
# keymaps, visual mode and editing bindings (see
# ~/.config/zsh/conf.d/plugins.zsh).
setopt vi
export KEYTIMEOUT=1

# --- Cursor Shape Switching (Works natively in Ghostty) ---
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q' # Block cursor in Normal mode
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q' # Beam cursor in Insert mode
  fi
}
zle -N zle-keymap-select

# Ensure beam cursor appears when a new prompt starts
zle-line-init() {
  zle -K viins
  echo -ne '\e[5 q'
}
zle -N zle-line-init

# --- Edit Long Commands in $EDITOR (Ctrl+V in Normal Mode) ---
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '^V' edit-command-line

# --- Hybrid Emacs Bindings in Insert Mode (viins) ---
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank

# Word movement & editing (Requires Option-as-Alt in Ghostty on macOS)
bindkey -M viins '\eb' backward-word
bindkey -M viins '\ef' forward-word
bindkey -M viins '\ed' kill-word
bindkey -M viins '\e^?' backward-kill-word

# History & character navigation
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^F' forward-char
bindkey -M viins '^B' backward-char
bindkey -M viins '^D' delete-char-or-list

# Fix Backspace across modes after pressing Esc
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# Bind 'V' in normal mode to open the command line in nvim
# (overrides the vi-mode plugin's visual-line-mode binding)
bindkey -M vicmd 'V' edit-command-line