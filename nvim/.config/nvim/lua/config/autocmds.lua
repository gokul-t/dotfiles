
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Open the Snacks explorer only when no file was passed on the command line
    if #vim.fn.argv() > 0 then
      return
    end

    -- Opens Snacks explorer in the project root without stealing cursor focus
    Snacks.explorer({ cwd = LazyVim.root(), enter = false })
  end,
})
