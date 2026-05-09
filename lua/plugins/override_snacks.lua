return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
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
