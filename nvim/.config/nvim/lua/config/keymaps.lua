-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("t", "<C-[>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })
vim.keymap.set(
  "x",
  "<leader>p",
  [["_dP]],
  { noremap = true, desc = "delete and paste without overwriting the default register" }
)
