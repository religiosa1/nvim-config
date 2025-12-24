-- Github Codeowners plugin
-- https://github.com/comatory/gh-co.nvim
return {
  -- "comatory/gh-co.nvim",
  "religiosa1/gh-co.nvim",
  -- dir = "~/Projects/gh-co.nvim/",
  -- enabled = false,
  version = "*",
  config = function()
    vim.keymap.set("n", "<leader>go", ":GhCoWho<CR>", { desc = "CodeOwner" })
  end,
}
