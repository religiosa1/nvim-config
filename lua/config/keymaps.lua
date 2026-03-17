-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>uW", function()
  vim.o.list = not vim.o.list
end, { desc = "Toggle whitespace display" })

vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>", { desc = "Open new buffer" })
vim.keymap.set("n", "<leader>bm", function()
  vim.cmd("enew")
  vim.bo.filetype = "markdown"
end, { desc = "Open new markdown buffer" })

vim.keymap.set("i", "<C-в>", "<Delete>")
vim.keymap.set("i", "<C-d>", "<Delete>", { desc = "Delete forward" })
vim.keymap.set("i", "<C-ы>", "<C-o>dw")
vim.keymap.set("i", "<C-s>", "<C-o>dw", { desc = "Delete forward word" })
vim.keymap.set("i", "<C-ц>", "<C-w>")

-- Go To definition in a horizontal split
vim.keymap.set("n", "gh", "<C-w>v:lua Snacks.picker.lsp_definitions()<CR>", { desc = "Go to definition in Vsplit" })

-- Extended default <C-g>: also yanking the filename
local function yankAboslutePath()
  vim.fn.setreg("+", vim.fn.expand("%:~"))
  vim.cmd("file")
end

vim.keymap.set("n", "<C-g>", yankAboslutePath, { desc = "Show file info and yank filename" })
vim.keymap.set("n", "<C-п>", yankAboslutePath)

-- Copy relative file path to clipboard and notify
local function yankRelativePath()
  local relative_path = vim.fn.expand("%:.")
  vim.fn.setreg("+", relative_path)
  vim.notify(relative_path, vim.log.levels.INFO, { title = "Copied file name", ft = "text" })
end
vim.keymap.set("n", "<C-s>", yankRelativePath, { desc = "Copy relative path to clipboard" })
vim.keymap.set("n", "<C-ы>", yankRelativePath)

-- A lot of stuff for cut/paste without register
vim.keymap.set("v", "<leader>p", "pgvy", { desc = "Paste w/o clipboard" })

function ReplaceWithRegister(type)
  if type == "char" then
    vim.cmd('normal! `[v`]"_dP')
  elseif type == "line" then
    vim.cmd('normal! `[V`]"_dP')
  end
end

vim.keymap.set("n", "gR", function()
  vim.o.operatorfunc = "v:lua.ReplaceWithRegister"
  return "g@"
end, { expr = true, desc = "Replace with register" })

vim.keymap.set("n", "gRR", '"_ddP', { desc = "Replace line" })
vim.keymap.set("x", "gR", '"_dP', { desc = "Replace with register" })

vim.keymap.set({ "v" }, "x", '"_d', { desc = "Delete to blackhole" })
vim.keymap.set({ "n", "o", "x" }, "<LocalLeader>x", '"_x', { desc = "X to blackhole" })
vim.keymap.set({ "n", "v", "o", "x" }, "<LocalLeader>d", '"_d', { desc = "Delete to blackhole" })
vim.keymap.set({ "n", "v", "o", "x" }, "<LocalLeader>d", '"_d', { desc = "Delete to blackhole" })

-- Cookbook spell checks toggle
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

-- Bufferline move buffers around and a shorter "pick buffer"
vim.keymap.set("n", "<A-H>", "<cmd>BufferLineMovePrev<cr>")
vim.keymap.set("n", "<A-L>", "<cmd>BufferLineMoveNext<cr>")
vim.keymap.set("n", "<A-J>", "<cmd>BufferLinePick<cr>")
