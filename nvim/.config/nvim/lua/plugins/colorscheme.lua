return {
  -- 1. Install your matching theme (e.g., Catppuccin)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- Match this to your Ghostty & Tmux style
      transparent_background = true, -- Set to true if you like transparent terminals
      float = {
        transparent = true, -- Makes floating windows and Snacks pickers/explorer transparent
        solid = false,
      },
      auto_integrations = true, -- Automatically applies Catppuccin styling to snacks.nvim
    },
  },

  -- 2. Direct LazyVim to load this specific theme upon launch
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha", -- Match this to your Ghostty & Tmux style:
    },
  },
}
