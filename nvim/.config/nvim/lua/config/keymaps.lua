-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = require("utils.keymaps").map
local xnoremap = require("utils.keymaps").xnoremap
-- local nnoremap = require("utils.keymaps").nnoremap

map("t", "<C-[>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })

xnoremap("<leader>p", [["_dP]])
