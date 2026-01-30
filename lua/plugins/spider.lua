return {
  {
    "chrisgrieser/nvim-spider",
    keys = {
      {
        "<localleader>w",
        "<cmd>lua require('spider').motion('w')<CR>",
        mode = { "n", "o", "x" },
        desc = "Spider Word",
      },
      { "<localleader>e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" }, desc = "Spider End" },
      {
        "g<localleader>e",
        "<cmd>lua require('spider').motion('ge')<CR>",
        mode = { "n", "o", "x" },
        desc = "Spider Previous End",
      },
      {
        "<localleader>b",
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { "n", "o", "x" },
        desc = "Spider Back",
      },
    },
    opts = {
      skipInsignificantPunctuation = false,
    },
  },
}
