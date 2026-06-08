return {
  "folke/snacks.nvim",
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
      -- Plugin is disabled by default, so no inline rending is there in markdown
      enabled = true,
    },
    explorer = {
      -- disabling snacks explorer as the default dir viewer in favor of mini.files
      replace_netrw = false,
    },
    picker = {
      win = {
        input = {
          keys = {
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
