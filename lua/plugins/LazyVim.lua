-- if true then
--   return {}
-- end
return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Disabling some of the default lsp kinds in typescript to de-clutter LSP search
      local ts_lsp_kinds = vim.tbl_filter(function(kind)
        return kind ~= "Property"
      end, opts.kind_filter.default)
      -- We may considering adding this later (not included by default):
      -- "Variable",
      -- "Constant",

      return vim.tbl_deep_extend("force", opts, {
        kind_filter = {
          typescript = ts_lsp_kinds,
          typescriptreact = ts_lsp_kinds,
        },
      })
    end,
  },
}
