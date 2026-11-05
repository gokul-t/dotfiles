# Shell Configuration Role

## Packages

| Package | Purpose |
|---------|---------|
| `zsh/` | Oh My Zsh config with auto-suggestions, syntax highlighting |
| `tmux/` | Terminal multiplexer with shared navigation |
| `starship/` | Cross-shell customizable prompt |
| `sesh/` | Tmux session management |
| `mise/` | Tool version manager (Java, Node, Python, Rust) |
| `lazygit/` | Git TUI |
| `yazi/` | File manager TUI |
| `ghostty/` | Terminal emulator config |
| `alacritty/` | Alternative terminal config |
| `bin/` | User-space tools |

## Key Bindings

### Tmux Navigation
- `prefix + I` : Install plugins
- `prefix + r` : Reload config
- `prefix + h/v` : Split window

### Zsh Features
- Auto-venv: automatic Python venv activation
- Vi-Mode: `V` to edit command in Neovim

## Validation
```sh
zsh -c 'echo ok'
```
