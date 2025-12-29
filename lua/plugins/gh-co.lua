-- Github Codeowners plugin
-- https://github.com/comatory/gh-co.nvim
return {
  "comatory/gh-co.nvim",
  config = function()
    vim.keymap.set("n", "<leader>go", ":GhCoWho<CR>", { desc = "CodeOwner" })
  end,
}
