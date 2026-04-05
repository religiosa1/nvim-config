return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    image = {
      -- Plugin is disabled by default, so no inline rending is there in markdown
      enabled = true,
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
