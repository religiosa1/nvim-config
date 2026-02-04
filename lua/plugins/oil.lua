return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      float = {
        -- Padding around the floating window
        padding = 2,
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0.85,
        max_height = 0.85,
        -- see :help nvim_open_win
        border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
      },
    },
    -- Optional dependencies
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    -- that's a fork of benomahony/oil-git.nvim, as that plugin has really bad performance
    "smiggiddy/git-oil.nvim",
    dependencies = { "stevearc/oil.nvim" },
    opts = {},
  },
}
