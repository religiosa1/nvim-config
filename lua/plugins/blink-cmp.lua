return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        trigger = {
          show_on_insert_on_trigger_character = false,
        },
        list = {
          selection = {
            preselect = true,
            auto_insert = true,
          },
        },
        accept = {
          -- not entirely sure I like it, keeping it here for maybe disabling later
          auto_brackets = {
            enabled = true,
            -- fall back to semantic-token resolution instead of blindly adding ()
            -- for any Function/Method-kind item: fixes svelte css pseudo-class
            -- completions (::after etc.) and reduces spurious () when passing
            -- a function as a callback arg
            kind_resolution = {
              blocked_filetypes = {
                "typescriptreact",
                "javascriptreact",
                "vue",
                "typescript",
                "javascript",
                "svelte",
              },
            },
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
        ["<C-space>"] = {}, -- show documentation -- remapped bellow
        ["<A-m>"] = { "show_documentation", "hide_documentation" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "show", "select_next", "fallback_to_mappings" },
        -- <Tab>/<S-Tab> are owned by mini.keymap (snippet -> menu -> pair/tsnode
        -- jump -> indent). blink maps buffer-locally and would shadow the global
        -- mini mapping, so it has to give the key up entirely.
        ["<Tab>"] = {},
        ["<S-Tab>"] = {},

        -- close the menu without leaving insert mode -- InsertLeave moves the
        -- cursor off the tabstop, which kills the vim.snippet session
        ["<Esc>"] = { "cancel", "fallback" },

        -- ["<Up>"] = { "snippet_forward", "fallback" },
        -- ["<Down>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
      },
    },
  },
}
