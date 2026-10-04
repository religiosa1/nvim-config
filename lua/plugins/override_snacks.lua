local FileUtils = require("util.files")

---Close the picker and pass the item's absolute path to `yank`.
---@param picker snacks.Picker
---@param item snacks.picker.Item?
---@param yank fun(path: string)
local function yank_item_path(picker, item, yank)
  local path = Snacks.picker.util.path(item)
  if not path then
    vim.notify("Item is not a file", vim.log.levels.WARN)
    return
  end
  -- leave insert mode before closing, so the deferred stopinsert doesn't nudge the main window cursor
  picker:norm(function()
    picker:close()
    yank(path)
  end)
end

return {
  "folke/snacks.nvim",
  -- Drop the snacks_picker git-diff binds (<leader>gd hunks, <leader>gD origin)
  -- to free them for diffview
  keys = {
    { "<leader>gd", false }, -- Git Diff (hunks)
    { "<leader>gD", false }, -- Git Diff (origin)
    { "<leader>gi", false }, -- GitHub Issues (open)
    { "<leader>gI", false }, -- GitHub Issues (All)
    { "<leader>gL", false }, -- GitHub Issues (All)
  },
  ---@type snacks.Config
  opts = {
    styles = {
      lazygit = {
        width = 0.96,
        height = 0.96,
        keys = {
          -- Override double-escape: hide lazygit instead of entering normal mode
          term_normal = {
            "<esc>",
            function(self)
              self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
              if self.esc_timer:is_active() then
                self.esc_timer:stop()
                self:hide()
              else
                self.esc_timer:start(vim.o.timeoutlen, 0, function() end)
                return "<esc>"
              end
            end,
            mode = "t",
            expr = true,
            desc = "Double escape to close lazygit",
          },
        },
      },
    },
    statuscolumn = { refresh = 150 }, -- ms; default is fast
    image = {
      -- this requires kitty graphics protocol, so will work in ghostty, but not in foot
      enabled = true,
      -- overriding defaults here, rendering images in floats only
      doc = {
        inline = false,
        float = true,
      },
      math = {
        enabled = true,
      },
    },
    explorer = {
      -- disabling snacks explorer as the default dir viewer in favor of mini.files
      replace_netrw = false,
    },
    picker = {
      actions = {
        yank_path_cwd = function(picker, item)
          yank_item_path(picker, item, FileUtils.yank_relative_path)
        end,
        yank_path_buf = function(picker, item)
          local target_buf = vim.api.nvim_win_get_buf(picker.main)
          local target_name = vim.api.nvim_buf_get_name(target_buf)
          if target_name == "" or vim.bo[target_buf].buftype ~= "" then
            vim.notify("Target buffer is not a file", vim.log.levels.WARN)
            return
          end
          yank_item_path(picker, item, function(path)
            FileUtils.yank_path_relative_to(path, vim.fs.dirname(target_name))
          end)
        end,
        yank_path_abs = function(picker, item)
          yank_item_path(picker, item, FileUtils.yank_absolute_path)
        end,
        yank_files = function(picker)
          local paths = vim
            .iter(picker:selected { fallback = true })
            :map(Snacks.picker.util.path)
            :totable()
          if #paths == 0 then
            vim.notify("No files selected", vim.log.levels.WARN)
            return
          end
          picker:norm(function()
            picker:close()
            FileUtils.copy_files_to_clipboard(paths)
          end)
        end,
      },
      win = {
        input = {
          keys = {
            ["<c-y>y"] = { "yank_path_cwd", mode = { "n", "i" }, desc = "Yank path relative to cwd" },
            ["<c-y>r"] = { "yank_path_buf", mode = { "n", "i" }, desc = "Yank path relative to buf" },
            ["<c-y>Y"] = { "yank_path_abs", mode = { "n", "i" }, desc = "Yank absolute path" },
            ["<c-y>f"] = { "yank_files", mode = { "n", "i" }, desc = "Copy files to system clipboard" },
            -- remapping <a-h> to <a-o> to avoid conflicts with tmux keybinds
            -- Not mnemonical, but right next to <a-i> for ignored
            ["<a-o>"] = {
              "toggle_hidden",
              mode = { "n", "i" },
            },
          },
        },
      },
    },
  },
}
