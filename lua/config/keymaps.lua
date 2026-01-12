local outline = require("config.outline")

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>uW", function()
  vim.o.list = not vim.o.list
end, { desc = "Toggle whitespace display" })

-- Store the last non-empty colorcolumn value
local last_cc = "80,120,140"
-- Track changes to colorcolumn from any source
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "colorcolumn",
  callback = function()
    local current = vim.v.option_new
    if current ~= "" then
      last_cc = current
    end
  end,
})
-- Actually setting colorcolumn on keymap
vim.keymap.set("n", "<leader>uR", function()
  if vim.o.cc == "" then
    vim.opt.cc = last_cc
  else
    vim.opt.cc = ""
  end
end, { desc = "Toggle ruler guides" })

vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>", { desc = "Open new buffer" })

vim.keymap.set("i", "<C-d>", "<Delete>", { desc = "Delete forward" })
vim.keymap.set("i", "<C-s>", "<C-o>dw", { desc = "Delete forward word" })

-- Go To definition in a horizontal split
vim.keymap.set("n", "gh", "<C-w>v:lua Snacks.picker.lsp_definitions()<CR>", { desc = "Go to definition in Vsplit" })

-- Extended default <C-g>: also yanking the filename
vim.keymap.set("n", "<C-g>", function()
  vim.fn.setreg("+", vim.fn.expand("%:~"))
  vim.cmd("file")
end, { desc = "Show file info and yank filename" })

-- A lot of stuff for cut/paste without register
vim.keymap.set("v", "<leader>p", "pgvy", { desc = "Paste w/o clipboard" })
vim.keymap.set({ "v" }, "x", '"_d', { desc = "Delete to blackhole" })
vim.keymap.set({ "n", "o", "x" }, "<LocalLeader>x", '"_x', { desc = "X to blackhole" })
vim.keymap.set({ "n", "v", "o", "x" }, "<LocalLeader>d", '"_d', { desc = "Delete to blackhole" })
vim.keymap.set({ "n", "v", "o", "x" }, "<LocalLeader>d", '"_d', { desc = "Delete to blackhole" })

vim.keymap.set("n", "<leader>ue", function()
  if vim.lsp.is_enabled("codebook") then
    vim.lsp.enable("codebook", false)
    vim.diagnostic.reset()
    vim.notify("Disabled codebook", vim.log.levels.WARN, { title = "Spelling" })
  else
    vim.lsp.enable("codebook", true)
    vim.notify("Enabled codebook", { title = "Spelling" })
  end
end, { desc = "Toggle Codebook Sp[e]lling" })

--More sane exit terminal mode
vim.keymap.set("t", "<C-Esc>", "<C-\\><C-n>", { remap = true, desc = "Exit terminal mode" })

-- scroll and center
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { remap = true })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { remap = true })

-- compatibility with vim-surround for mini.surrounding plugin
vim.keymap.set("n", "ys", "gsa", { remap = true, desc = "Add surrounding" })
vim.keymap.set("n", "ds", "gsd", { remap = true, desc = "Delete surrounding" })
vim.keymap.set("n", "cs", "gsr", { remap = true, desc = "Replace surrounding" })
vim.keymap.set("v", "S", "gsa", { remap = true, desc = "Add surrounding" })

-- Custom de-cluttered <Leader>ss picker for outline
vim.keymap.set("n", "<leader>sf", function()
  local ft = vim.bo.filetype
  if ft == "typescript" or ft == "typescriptreact" then
    return Snacks.picker({
      title = "Outline (treesitter)",
      items = outline(),
      format = "lsp_symbol",
      tree = true,
      auto_confirm = false,
      show_empty = true,
      jump = { tagstack = true, reuse_win = true },
    })
  else
    Snacks.picker.lsp_symbols({
      title = "Outline (LSP)",
      filter = { default = { "Class", "Function", "Method", "Constructor", "Enum" } },
    })
  end
end, { desc = "Outline" })
