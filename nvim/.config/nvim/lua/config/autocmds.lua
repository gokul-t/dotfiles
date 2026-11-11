
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Opens Snacks explorer in the project root without stealing cursor focus
    Snacks.explorer({ cwd = LazyVim.root(), enter = false })
  end,
})
