-- Customizing LSP symbols behavior, moving some of the LSP symbols behind
-- "ignored" and "hidden" toggles.
-- if true then
--   return {}
-- end

local function get_extended_lsp_kind()
  local kind_filter = vim.deepcopy(LazyVim.config.kind_filter)
  local ft = vim.bo.filetype
  assert(kind_filter)

  if type(kind_filter[ft]) == "table" then
    if vim.g._lsp_symbols_hidden then
      local hidden = LazyVim.config.kind_filter[ft .. "_h"]
      if hidden then
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.list_extend(kind_filter[ft], hidden)
      end
    end

    if vim.g._lsp_symbols_ignored then
      local ignored = LazyVim.config.kind_filter[ft .. "_i"]
      if ignored then
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.list_extend(kind_filter[ft], ignored)
      end
    end
  end

  return kind_filter
end

local function restart_picker(picker, type)
  local pattern = picker.input and picker.input.filter.pattern or ""
  local search = picker.input and picker.input.filter.search or ""
  picker:close()
  local filter = get_extended_lsp_kind()
  vim.schedule(function()
    Snacks.picker[type]({
      filter = filter,
      ignored = vim.g._lsp_symbols_ignored,
      hidden = vim.g._lsp_symbols_hidden,
      pattern = pattern,
      search = search,
    })
  end)
end

return {
  {
    "LazyVim/LazyVim",
    opts = function(plugin, opts)
      -- Disabling some of the default lsp kinds in typescript to de-clutter LSP search
      -- copied from LazyVim.config.kind_filter
      local ts_lsp_kinds = {
        "Class",
        "Constructor",
        "Enum",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Package",
      }
      local ts_lsp_kinds_ignored = {
        "Property",
        "Struct",
        "Trait",
      }
      local ts_lsp_kinds_hidden = {
        "Variable",
        "Constant",
      }

      return vim.tbl_deep_extend("force", opts, {
        kind_filter = {
          typescript = ts_lsp_kinds,
          typescript_h = ts_lsp_kinds_hidden,
          typescript_i = ts_lsp_kinds_ignored,

          typescriptreact = ts_lsp_kinds,
          typescriptreact_h = ts_lsp_kinds_hidden,
          typescriptreact_i = ts_lsp_kinds_ignored,
        },
      })
    end,
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          toggle_ignored_symbols = function(picker)
            vim.g._lsp_symbols_ignored = not vim.g._lsp_symbols_ignored
            restart_picker(picker, "lsp_symbols")
          end,
          toggle_hidden_symbols = function(picker)
            vim.g._lsp_symbols_hidden = not vim.g._lsp_symbols_hidden
            restart_picker(picker, "lsp_symbols")
          end,
          toggle_ignored_workspace_symbols = function(picker)
            vim.g._lsp_symbols_ignored = not vim.g._lsp_symbols_ignored
            restart_picker(picker, "lsp_workspace_symbols")
          end,
          toggle_hidden_workspace_symbols = function(picker)
            vim.g._lsp_symbols_hidden = not vim.g._lsp_symbols_hidden
            restart_picker(picker, "lsp_workspace_symbols")
          end,
        },
        sources = {
          lsp_symbols = {
            win = {
              input = {
                keys = {
                  ["<a-i>"] = {
                    "toggle_ignored_symbols",
                    mode = { "i", "n" },
                    desc = "Toggle Ignored Symbols",
                  },
                  ["<a-o>"] = {
                    "toggle_hidden_symbols",
                    mode = { "i", "n" },
                    desc = "Toggle Hidden Symbols",
                  },
                },
              },
            },
          },
          lsp_workspace_symbols = {
            win = {
              input = {
                keys = {
                  ["<a-i>"] = {
                    "toggle_ignored_workspace_symbols",
                    mode = { "i", "n" },
                    desc = "Toggle Ignored Symbols",
                  },
                  ["<a-o>"] = {
                    "toggle_hidden_workspace_symbols",
                    mode = { "i", "n" },
                    desc = "Toggle Hidden Symbols",
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
