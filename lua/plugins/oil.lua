-- I mostly use oil as a netrw replacement for now. The main file explorer is mini.files now.

local FileUtils = require("util.files")

local function float_only_close()
  local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
  if is_float then
    require("oil").close()
  end
end

---Absolute path of the entry under the cursor in an oil buffer.
---@return string
local function get_selection_path()
  local oil = require("oil")
  local dir = oil.get_current_dir()
  local entry = oil.get_cursor_entry()
  if not dir or not entry then
    error("No file or directory selected")
  end
  return dir .. entry.name
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
        ["<Esc><Esc>"] = { float_only_close, mode = "n", desc = "Close float window" },
        ["<C-s>"] = false,
        ["g<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open file in VSplit" },
        ["<leader>yy"] = {
          function()
            FileUtils.yank_relative_path(get_selection_path())
          end,
          mode = "n",
          desc = "Yank relative file path",
        },
        ["<leader>yY"] = {
          function()
            FileUtils.yank_absolute_path(get_selection_path())
          end,
          mode = "n",
          desc = "Yank absolute file path",
        },
        ["<leader>yf"] = {
          function()
            if vim.fn.mode() ~= "n" then
              local oil = require("oil")
              local dir = oil.get_current_dir()
              FileUtils.copy_visual_selection_to_clipboard(function(lnum)
                local entry = oil.get_entry_on_line(0, lnum)
                return dir and entry and (dir .. entry.name)
              end)
            else
              FileUtils.copy_files_to_clipboard { get_selection_path() }
            end
          end,
          mode = { "n", "x" },
          desc = "Yank file(s) to system clipboard",
        },
        ["<leader>e"] = {
          function()
            FileUtils.open_file(get_selection_path())
          end,
          mode = "n",
          desc = "Open in the system app",
        },
        ["<leader>o"] = {
          function()
            local oil = require("oil")
            local dir = oil.get_current_dir()
            if not dir then
              vim.notify("No directory", vim.log.levels.WARN)
              return
            end
            float_only_close()
            require("mini.files").open(dir)
          end,
          mode = "n",
          desc = "Open current directory in mini.files",
        },
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
        "<leader>O",
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
    --
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  -- {
  --   -- that's a fork of benomahony/oil-git.nvim, as that plugin has really bad performance
  --   "smiggiddy/git-oil.nvim",
  --   dependencies = { "stevearc/oil.nvim" },
  --   opts = {},
  -- },
}
