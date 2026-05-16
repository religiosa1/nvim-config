return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- disabling inlay hints by default, still can be toggled with <leader>uh
    opts.inlay_hints = { enabled = false }
    opts.servers = opts.servers or {}
    opts.servers.marksman = { enabled = false }
    -- markdown-oxide
    opts.servers.markdown_oxide = {
      -- Ensure that dynamicRegistration is enabled
      -- This allows the LS to take into account actions like Create Unresolved File, etc
      capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities(),
        {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        }
      ),
      on_attach = function(client, bufnr)
          -- normalize vim.NIL scheme values so mini.files doesn't crash on sync
          local file_ops = vim.tbl_get(client, "server_capabilities", "workspace", "fileOperations")
          if file_ops then
            for _, method_filters in pairs(file_ops) do
              if type(method_filters) == "table" and method_filters.filters then
                for _, fc in ipairs(method_filters.filters) do
                  if fc.scheme == vim.NIL then fc.scheme = nil end
                end
              end
            end
          end

          local function codelens_supported(bufnr)
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
              if c.server_capabilities and c.server_capabilities.codeLensProvider then
                return true
              end
            end
            return false
          end

          vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold", "BufEnter" }, {
            buffer = bufnr,
            callback = function()
              if codelens_supported(bufnr) then
                vim.lsp.codelens.enable(true, { bufnr = bufnr })
              end
            end,
          })

          if codelens_supported(bufnr) then
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end
        end,
    }
    return opts
  end,
}
