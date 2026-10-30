return {

  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      opts.options.always_show_bufferline = true
      opts.options.diagnostics = false
      opts.options.diagnostics_indicator = nil
      if (vim.g.colors_name or ""):find("catppuccin") then
        opts.highlights = require("catppuccin.special.bufferline").get_theme()
      end
    end,
  }

}
