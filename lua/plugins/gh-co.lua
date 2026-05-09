-- Github Codeowners plugin
-- https://github.com/comatory/gh-co.nvim
return {
  "comatory/gh-co.nvim",
  lazy = true,
  keys = {
    {
      "<leader>go",
      "<cmd>GhCoWho<CR>",
      desc = "CodeOwner",
      mode = { "n" },
    },
  },
}
