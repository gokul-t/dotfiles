return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    explorer = {},
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignore = true,
          exclude = { "node_modules", ".git" },
        },
      },
    },
  },
}
