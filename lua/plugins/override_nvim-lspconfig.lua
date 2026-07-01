return {
  "neovim/nvim-lspconfig",
  opts = {
    -- disabling inlay hints by default, still can be toggled with <leader>uh
    inlay_hints = { enabled = false },
    servers = {
      ["*"] = {
        keys = {
          -- Cyrillic (ЙЦУКЕН) duplicate of <leader>ca Code Action: с=c, ф=a
          {
            "<leader>сф",
            vim.lsp.buf.code_action,
            desc = "Code Action",
            mode = { "n", "x" },
            has = "codeAction",
          },
        },
      },
    },
  },
}
