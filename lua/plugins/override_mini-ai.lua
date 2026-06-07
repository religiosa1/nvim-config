return {
  {
    "nvim-mini/mini.ai",
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      -- "m" for method-chain link, incl. the leading '.' or ':' -- and potentially trailing . for go
      -- %s between . and the word is for capturing trailing . syntax, as in golang
      opts.custom_textobjects.m = {
        "[.:]%s*[%w_]+%b()", -- around
        "^[.:]%s*[%w_]+%(().*()%)$", -- inner
      }
    end,
  },
  -- which-key helper to go with it
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.spec, {
        {
          mode = { "x", "o" }, -- visual + operator-pending, same as mini.ai's objects
          { "am", desc = "method chain link" },
          { "im", desc = "method chain args" },
        },
      })
    end,
  },
}
