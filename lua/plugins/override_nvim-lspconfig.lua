local langmap = require("util.langmap")

return {
  "neovim/nvim-lspconfig",
  opts = {
    -- disabling inlay hints by default, still can be toggled with <leader>uh
    inlay_hints = { enabled = false },
    servers = {
      ["*"] = {
        keys = {
          -- langmapped duplicate of LazyVim's <leader>ca Code Action
          {
            langmap.get("<leader>ca"),
            vim.lsp.buf.code_action,
            mode = { "n", "x" },
            has = "codeAction",
          },
        },
      },
    },
  },
}
