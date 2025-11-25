return {
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "<localleader>w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
      { "<localleader>e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
      { "<localleader>b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
    },
    opts = {
      skipInsignificantPunctuation = false,
    },
  },
}
