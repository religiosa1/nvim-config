return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    image = {
      -- Plugin is disabled by default, so no inline rending is there in markdown
      enabled = true,
      resolve = function(path, src)
        -- Obsidian md images resolving.
        local api = require("obsidian.api")
        local is_note_page = api.path_is_note(path)
        if is_note_page then
          return api.resolve_attachment_path(src)
        end
      end,
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
    }
  },
}
