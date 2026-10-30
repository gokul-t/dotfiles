-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.o.swapfile = false
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "pyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"
vim.g.autoformat = false

-- Enable 24-bit RGB color processing inside TUIs
vim.opt.termguicolors = true

-- Use tmux buffers inside tmux instead of launching wl-paste on Wayland.
if vim.env.TMUX and vim.fn.has("mac") == 0 then
  vim.g.clipboard = "tmux"
end
