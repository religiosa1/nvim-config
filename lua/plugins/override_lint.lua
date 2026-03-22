return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Default linter is markdownlint-cli2, which sucks a bag of dicks
        markdown = {},
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = {
                ST1000 = false, -- annoying "each package must have docs"
              },
            },
          },
        },
      },
    },
  },
}
