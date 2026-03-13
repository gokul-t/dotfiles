local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true } -- Set good defaults
  if opts then
    options = vim.tbl_deep_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

local function nnoremap(lhs, rhs)
  map("n", lhs, rhs, {})
end

local function xnoremap(lhs, rhs)
  map("x", lhs, rhs, {})
end

return { map = map, nnoremap = nnoremap, xnoremap = xnoremap }
