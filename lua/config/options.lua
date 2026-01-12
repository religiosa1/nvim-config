-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "-->",
  trail = "·",
}
vim.opt.cc = "80,120,140"

-- setting terminal tab title
vim.opt.title = true
-- the most important part to avoid confusion -- when launching in just
-- directory (without a filename provided -- aka Scratch buffer), we're
-- displaying cwd folder name, which is most likely the project name
if vim.fn.argc() == 0 then
  vim.opt.titlestring = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. " - Nvim"
end
