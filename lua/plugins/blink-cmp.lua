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

      -- mimicking vscode -- both tab (from super-tab) and enter accepts
      -- keymap = {
      --   preset = "super-tab",
      --   ["<CR>"] = { "select_and_accept", "fallback" },
      -- },

      -- https://cmp.saghen.dev/configuration/keymap.html#enter
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },

        -- ["<Up>"] = { "snippet_forward", "fallback" },
        -- ["<Down>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-y>"] = {},
      },
    },
  },
}
