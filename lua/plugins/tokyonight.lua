return {
  "folke/tokyonight.nvim",
  lazy = true,
  opts = {
    style = "moon",
    on_colors = function(colors)
      -- It's the color of unused args and functions, etc. I can't see it
      -- on the background so we're making it brighter. Original was #444a73
      colors.terminal_black = "#548ad3"
    end,
  },
}
