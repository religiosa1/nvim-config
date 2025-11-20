-- github-flavored markdown previewer with mermaid support
return {
  {
    "wallpants/github-preview.nvim",
    cmd = { "GithubPreviewToggle" },
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
      -- local fns = gpreview.fns
      -- vim.keymap.set("n", "<leader>mpt", fns.toggle)
      -- vim.keymap.set("n", "<leader>mps", fns.single_file_toggle)
      -- vim.keymap.set("n", "<leader>mpd", fns.details_tags_toggle)
    end,
  },
}
