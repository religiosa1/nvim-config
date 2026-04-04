return {
  "folke/flash.nvim",
  opts = {
    modes = {
      char = {
        -- for now just disabling the backdrop for flash for movements f F t T
        -- keeping it for multi-line search mostly
        highlight = { backdrop = false },
        -- If we want to keep it partially a couple of extra options down below:
        autohide = true,
        -- enabled = false,
      },
    },
  },
  keys = {
    -- disable the default flash keymap
    { "s", mode = { "n", "x", "o" }, false },
    -- enabling it only for normal mode, so it doesn't conflict with ys from mini.surround
    { "s", mode = { "n" },           function() require("flash").jump() end, desc = "Flash" },
  }
}
