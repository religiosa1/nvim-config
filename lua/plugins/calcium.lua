-- Calcium plugin for performing math calculations on the v-selected text
-- Don't also forget about the builtin expression register aka "calculator":
-- in insert mode: ctrl+R, =
return {
  "necrom4/calcium.nvim",
  cmd = { "Calcium" },
  opts = {
    default_mode = "replace",
  },
  keys = {
    {
      "<leader>=",
      "<cmd>Calcium replace<CR>",
      desc = "Calculate",
      mode = { "n", "v" },
    },
  },
}
