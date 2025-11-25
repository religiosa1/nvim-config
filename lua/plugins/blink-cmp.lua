return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        accept = {
          -- not entirely sure I like it, keeping it here for maybe disabling later
          auto_brackets = {
            enabled = true,
          },
        },
      },
      keymap = {
        preset = "super-tab",
        -- mimicing vscode -- both tab (from super-tab) and enter accepts
        ["<CR>"] = { "select_and_accept", "fallback" },
      },
      -- maybe I want to disable ghost_text as well, research later:
      -- https://cmp.saghen.dev/configuration/general.html
    },
  },
}
