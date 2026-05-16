-- Configuration for golang templ language
-- https://templ.guide/
-- https://github.com/LazyVim/LazyVim/discussions/3735#discussioncomment-11306961
-- https://github.com/vrischmann/tree-sitter-templ

vim.api.nvim_create_autocmd("FileType", {
  pattern = "templ",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

return {
  {
    "vrischmann/tree-sitter-templ",
    build = ":TSUpdate templ",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        templ = {
          filetypes = { "templ" },
          settings = {
            templ = {
              enable_snippets = true,
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "templ",
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        templ = { "templ" },
      },
    },
  },
}
