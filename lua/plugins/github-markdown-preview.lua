-- github-flavored markdown previewer with mermaid support
-- Requires Bun.
return {
  {
    "wallpants/github-preview.nvim",
    -- default comand is "GithubPreviewToggle", but I'd never remember that
    cmd = { "MarkdownPreview" },
    -- keys = { "<leader>mpt" },
    opts = {
      details_tags_open = true,
      cursor_line = {
        opacity = 0.0,
      },
    },
    config = function(_, opts)
      local gpreview = require("github-preview")
      gpreview.setup(opts)
      local fns = gpreview.fns
      vim.api.nvim_create_user_command("MarkdownPreview", fns.toggle, {})
      -- vim.keymap.set("n", "<leader>mpt", fns.toggle)
      -- vim.keymap.set("n", "<leader>mps", fns.single_file_toggle)
      -- vim.keymap.set("n", "<leader>mpd", fns.details_tags_toggle)
    end,
  },
}
