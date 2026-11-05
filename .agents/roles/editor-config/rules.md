# Editor Configuration Role

## Packages

| Package | Purpose |
|---------|---------|
| `nvim/` | Neovim config (LazyVim with LSP) |
| `vim/` | Vim fallback config |
| `ideavim/` | IntelliJ IDEA vim config |
| `code/` | VS Code settings |

## Validation Commands

```sh
# Check Neovim health
nvim --headless -c 'checkhealth' -c 'qa!'

# Test Vim config
vim -c 'qa!'
```

## Key Files

- `nvim/lazyvim/` - LazyVim configuration
- `nvim/init.lua` - Neovim entry point
- `nvim/lua/` - Custom Lua modules
