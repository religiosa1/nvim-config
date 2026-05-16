return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
  config = function()
    require("treesj").setup({
      use_default_keymaps = false,
      max_join_length = 1200, -- default is 120
    })
  end,
  keys = {
    {
      "<leader>jj",
      function()
        require("treesj").toggle()
      end,
      desc = "block of code toggle split/join",
      mode = { "n", "x" },
    },
    {
      "<leader>jJ",
      function()
        require("treesj").join()
      end,
      desc = "block of code join",
      mode = { "n", "x" },
    },
    {
      "<leader>js",
      function()
        require("treesj").split()
      end,
      desc = "block of code split",
      mode = { "n", "x" },
    },
  },
}
