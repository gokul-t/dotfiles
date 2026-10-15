return {
  -- 1. Install your matching theme (e.g., Catppuccin)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "macchiato", -- Match this to your Ghostty & Tmux style
      transparent_background = false, -- Set to true if you like transparent terminals
    },
  },

  -- 2. Direct LazyVim to load this specific theme upon launch
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
    },
  },
}
