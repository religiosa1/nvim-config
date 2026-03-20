return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
  config = function()
    require("treesj").setup({
      use_default_keymaps = false,
    })
  end,
  keys = {
    {
      "<leader>jm",
      function()
        require("treesj").toggle()
      end,
      desc = "block of code toggle split/join",
      mode = { "n", "v" },
    },
    {
      "<leader>jj",
      function()
        require("treesj").join()
      end,
      desc = "block of code join",
      mode = { "n", "v" },
    },
    {
      "<leader>js",
      function()
        require("treesj").split()
      end,
      desc = "block of code split",
      mode = { "n", "v" },
    },
  },
}
