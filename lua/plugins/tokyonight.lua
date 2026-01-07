return {
  "folke/tokyonight.nvim",
  lazy = true,
  opts = {
    style = "moon",
    -- List of defaults: https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
    on_highlights = function(colors)
      -- It's the color of unused args and functions, etc. I can't see it
      -- on the background so we're making it brighter. Original was #444a73 or colors.terminal_black
      -- Overriding terminal_black color completely also messes up markdown_inline and ghost text for
      -- autocompletion, so we're doing it in a more precise manner.
      colors.DiagnosticUnnecessary = {
        fg = "#548ad3",
      }
    end,
    -- on_colors = function(colors)
    --   colors.terminal_black = "#548ad3"
    -- end,
  },
}
