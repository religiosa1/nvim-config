local function float_only_close()
  local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
  if is_float then
    require("oil").close()
  end
end

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
        -- see :help 'winborder' and :help nvim_open_win
        border = "double",
      },
      keymaps = {
        q = { float_only_close, mode = "n", desc = "Close float window" },
        ["<Esc>"] = { float_only_close, mode = "n", desc = "Close float window" },
      },
    },
    keys = {
      {
        "<leader>o",
        "<cmd>lua require('oil').open_float()<CR>",
        desc = "Open Oil in the current folder",
        mode = { "n" },
        silent = true,
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
