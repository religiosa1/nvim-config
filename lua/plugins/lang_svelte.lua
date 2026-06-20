vim.api.nvim_create_autocmd("FileType", {
  pattern = "svelte",
  -- disabling t-s indents in svelte, as they suck ass
  callback = function()
    vim.bo.indentexpr = ""
  end,
})
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- All of the required t-s grammars for "proper" operation
      vim.list_extend(opts.ensure_installed, {
        "svelte",
        "css",
        "scss",
        "javascript",
        "typescript",
        "html",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- upstream nvim-lspconfig's codebook filetypes list is missing svelte
      -- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/codebook.lua
      opts.servers = opts.servers or {}
      opts.servers.codebook = {
        filetypes = vim.list_extend({ "svelte" }, vim.lsp.config.codebook.filetypes or {}),
      }
    end,
  },
}
