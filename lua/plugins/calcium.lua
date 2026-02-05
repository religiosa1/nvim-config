-- Calcium for performing math calculations
return {
  "necrom4/calcium.nvim",
  cmd = { "Calcium" },
  opts = {
    default_mode = "replace",
  },
  keys = {
    {
      "<leader>=",
      ":Calcium replace<CR>",
      desc = "Calculate",
      mode = { "n", "v" },
      silent = true,
    },
  },
}
