-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disabling builtin-in spellchecker in favor of codebook for:
-- "text", "plaintex", "typst", "gitcommit", "markdown
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Enabling wrapping back though
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- vscode-style color markers (nvim v0.12+)
-- vim.lsp.document_color.color_presentation() for switching between gex and rgb, etc
-- Doing it in autocmd to avoid eagerly loading the full LSP thing
vim.api.nvim_create_autocmd("LspAttach", {
  once = true,
  callback = function()
    vim.lsp.document_color.enable(true, nil, { style = "virtual" })
  end,
})

-- syncing grug-far on write
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "grug-far" },
  callback = function(args)
    local buf_id = args.buf

    -- we need to schedule, as grug-far sets the option to none on buf setup
    vim.schedule(function()
      vim.bo[buf_id].buftype = "acwrite"
      -- also need a name for the buffer, or :w will complain
      if vim.api.nvim_buf_get_name(buf_id) == "" then
        vim.api.nvim_buf_set_name(buf_id, "grug-far://" .. buf_id)
      end

      vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf_id,
        callback = function()
          require("grug-far").get_instance(0):sync_all()
          vim.bo[buf_id].modified = false
        end,
      })
    end)
  end,
})
