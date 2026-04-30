return {
  "neovim/nvim-lspconfig",
  opts = {
    -- disabling inlay hints by default, still can be toggled with <leader>uh
    inlay_hints = {
      enabled = false,
      -- exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
    },
    servers = {
      marksman = {
        enabled = false,
      },
      -- markdown-oxide
      markdown_oxide = {
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
        on_attach = function(_client, bufnr)
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
      },
    },
  },
}
