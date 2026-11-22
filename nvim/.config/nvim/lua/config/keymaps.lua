-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- <C-[> and <Esc> are the same key byte (0x1b), but under the kitty keyboard
-- protocol they are reported as distinct sequences. We want lazygit/TUIs to
-- receive the same action for both keys: use Esc to close a submodule.
-- For plain shells (bash/zsh/fish/etc.) we map C-[ to exit terminal mode.
local shell_commands = {
  bash = true,
  zsh = true,
  fish = true,
  sh = true,
  dash = true,
  ksh = true,
  nu = true,
}

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev)
    local ok, snacks = pcall(vim.api.nvim_buf_get_var, ev.buf, "snacks_terminal")
    local cmd = ok and type(snacks) == "table" and snacks.cmd or nil
    local name = type(cmd) == "table" and vim.fs.basename(cmd[1] or "") or nil

    local is_shell = name and shell_commands[name]

    if is_shell then
      -- Map C-[ to exit terminal mode (same as Esc). Esc remains unmapped so it
      -- can be used normally for shell editing.
      vim.keymap.set("t", "<C-[>", "<C-\\><C-n>", { buffer = ev.buf, desc = "Exit terminal mode" })
    else
      -- For lazygit and other TUIs: map C-[ to <Esc> so it produces the same
      -- key that lazygit understands (e.g., closing a submodule).
      vim.keymap.set("t", "<C-[>", "<Esc>", { buffer = ev.buf, desc = "Send Esc to TUI" })
    end
  end,
})
vim.keymap.set(
  "x",
  "<leader>p",
  [["_dP]],
  { noremap = true, desc = "delete and paste without overwriting the default register" }
)
-- snacks.scroll animates scrolls and jumps. With a plain string mapping like
-- `<C-d>zz` the animation can run between the motion and `zz`, then overwrite
-- the centering, so the first press only scrolls. Running the motion and the
-- centering in a single `:normal!` call lets the final centered view be the
-- animation target.
local function move_and_center(motion, center)
  local count = vim.v.count > 0 and vim.v.count or ""
  vim.cmd("normal! " .. count .. motion .. center)
end

vim.keymap.set("n", "<C-d>", function()
  move_and_center(vim.api.nvim_replace_termcodes("<C-d>", true, false, true), "zz")
end, { desc = "move down 1/2 screen and center" })
vim.keymap.set("n", "<C-u>", function()
  move_and_center(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "zz")
end, { desc = "move up 1/2 screen and center" })
vim.keymap.set("n", "n", function()
  move_and_center("n", "zzzv")
end, { desc = "next and center" })
vim.keymap.set("n", "N", function()
  move_and_center("N", "zzzv")
end, { desc = "previous and center" })
