if true then
  return {}
end
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
        ["<C-s>"] = false,
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
      },
      view_options = {
        show_hidden = true,
      },
      confirmation = {
        border = "rounded",
      },
    },
    keys = {
      {
        "<leader>o",
        "<cmd>lua require('oil').toggle_float()<CR>",
        -- toggle with extra tricks to cleanup buffer contents on open. in case there are some edits left
        -- function()
        --   local oil = require("oil")
        --   if vim.w.is_oil_win then
        --     oil.close()
        --   else
        --     oil.open_float(nil, nil, function()
        --       local bufnr = vim.api.nvim_get_current_buf()
        --       local wins = vim.fn.win_findbuf(bufnr)
        --       -- Only the float itself has this buffer -- we're calling render
        --       -- to clean up potential edits in the float
        --       if #wins == 1 then
        --         require("oil.view").render_buffer_async(bufnr, {})
        --       end
        --     end)
        --   end
        -- end,
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
