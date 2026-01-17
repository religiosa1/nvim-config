return {
  "folke/flash.nvim",
  opts = {
    modes = {
      char = {
        -- for now just disabling the backdrop for flash for movements f F t T
        -- keeping it for multi-line search mostly
        highlight = { backdrop = false },
        -- If we want to keep it partially a couple of extra options down below:
        -- autohide = true,
        -- enabled = false,
      },
    },
  },
}
