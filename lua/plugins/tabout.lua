return {
  {
    "abecodes/tabout.nvim",
    disabled = false,
    event = "VeryLazy", -- repo recommends "InsertCharPre", but we want to save up on load time
    config = function()
      require("tabout").setup({
        tabkey = "<A-Tab>", -- key to trigger tabout, set to an empty string to disable; default is just tab, but this is confusing
        backwards_tabkey = "<A-S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = false, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = "<C-y>", -- reverse shift default action; remmaped to our custom <C-y> from default <C-d>
        enable_backwards = true, -- well ...
        completion = false, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "<", close = ">" },
        },
        ignore_beginning = false, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {}, -- tabout will ignore these filetypes
      })
    end,
    dependencies = { -- These are optional
      "nvim-treesitter/nvim-treesitter",
      -- "L3MON4D3/LuaSnip",
      -- "hrsh7th/nvim-cmp"
    },
    opt = true, -- Set this to true if the plugin is optional
    priority = 1000,
  },
}
