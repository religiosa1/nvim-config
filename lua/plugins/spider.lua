return {
  {
    "chrisgrieser/nvim-spider",
    keys = {
      -- In all modes, spider-motions are mapped with localleader
      {
        "<localleader>w",
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { "n", "o", "x", "v" },
        desc = "Spider Word",
      },
      {
        "<localleader>e",
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { "n", "o", "x", "v" },
        desc = "Spider End",
      },
      {
        "g<localleader>e",
        "<cmd>lua require('spider').motion('ge')<CR>",
        mode = { "n", "o", "x", "v" },
        desc = "Spider Previous End",
      },
      {
        "<localleader>b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "n", "o", "x", "v" },
        desc = "Spider Back",
      },
      -- In operator pending mode, we're allowing spider motions with a simple leader as well for convenience
      {
        "<leader>w",
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { "o" },
        desc = "Spider Word",
      },
      { "<leader>e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "o" }, desc = "Spider End" },
      {
        "g<leader>e",
        "<cmd>lua require('spider').motion('ge')<CR>",
        mode = { "o" },
        desc = "Spider Previous End",
      },
      {
        "<leader>b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "o" },
        desc = "Spider Back",
      },
    },
    opts = {
      skipInsignificantPunctuation = false,
    },
  },
}
