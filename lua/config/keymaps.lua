-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local langmap = require("util.langmap")

-- mapping <C-space> to noop, so we can switch keyboard layouts with it not affecting anything else
-- incremental treesitter is on S, see ../plugins/override_flash.lua:11
vim.keymap.set({ "n", "o", "x", "i" }, "<C-space>", "<nop>", { noremap = true })
-- insert mode: the terminal sends <C-space> as <C-@>, which triggers the
-- builtin i_CTRL-@ ("insert last inserted text + stop insert")
vim.keymap.set("i", "<C-@>", "<nop>", { noremap = true })

-- helix-like combinations for start-end of the line on the home row
local hidden = { desc = "which_key_ignore" }
langmap.set_keymap({ "n", "o", "x" }, "gh", "^", hidden)
langmap.set_keymap({ "n", "o", "x" }, "gH", "0", hidden)
langmap.set_keymap({ "n", "o", "x" }, "gl", "g_", hidden)
langmap.set_keymap({ "n", "o", "x" }, "gL", "$", hidden)

langmap.set_keymap("n", "<A-J>", "<cmd>keeppatterns s/\\s*$/,/<cr>J", {
  desc = "Join lines with comma",
})
langmap.set_keymap({ "n", "i" }, "<C-;>", function()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local is_insert = vim.api.nvim_get_mode().mode:match("^[iR]")
  if is_insert then
    col = math.max(col - 1, 0) -- <Esc> moves cursor one left
  end
  local at_word_start = col == 0 or vim.api.nvim_get_current_line():sub(col, col):match("%s")
  local keys = (is_insert and "<Esc>" or "")
    .. (at_word_start and "" or "B")
    .. "i<CR><Esc>"
    .. (is_insert and "A" or "l")
  vim.api.nvim_feedkeys(vim.keycode(keys), "ni", false)
end, { desc = "Move WORD to next line" })

-- move record macro to <C-q> from just q, as I apparently constantly hit q by accident
vim.keymap.set("n", "<C-q>", "q", { noremap = true, desc = "Record macro" })
langmap.set_keymap("n", "q", "<nop>", { noremap = true })
-- keep cmdline-window history reachable
vim.keymap.set("n", "q:", "q:", { noremap = true, desc = "Command history window" })
vim.keymap.set("n", "q/", "q/", { noremap = true, desc = "Search history window" })
vim.keymap.set("n", "q?", "q?", { noremap = true, desc = "Search history window (backward)" })

langmap.set_keymap("i", "<C-d>", "<Delete>", { desc = "Delete forward" })
langmap.set_keymap("i", "<C-s>", "<C-o>dw", { desc = "Delete forward word" })
vim.keymap.set("i", langmap.get("<C-w>"), "<C-w>")

-- Vim normally uses C-d in insert mode to decrease indent, but this conflicts with our delete binding
-- So let's switch that to <A-t>. <C-T> is already taken by ghostty and such
vim.keymap.set("i", "<A-t>", "<C-o><<", { silent = true })
-- for consistency with shell cursor jumps ctrl-a/ctrl-e in insert mode vim.keymap.set("i", "<C-a>", "<C-o>I", { silent = true })
vim.keymap.set("i", "<C-e>", "<C-o>A", { silent = true })
vim.keymap.set("i", "<A-f>", "<C-o>w", { silent = true })
vim.keymap.set("i", "<A-b>", "<C-o>b", { silent = true })

-- Go To definition in a vertical split
vim.keymap.set("n", "g<C-v>", "<C-w>v:lua Snacks.picker.lsp_definitions()<CR>", { desc = "Go to definition in Vsplit" })

require("which-key").add {
  {
    "<leader>y",
    group = "Yank file",
    mode = { "n" },
  },
}
vim.keymap.set("n", "<leader>yy", function()
  local path = vim.fn.expand("%:p")
  require("util.files").yank_relative_path(path)
end, { desc = "Yank relative path" })

vim.keymap.set("n", "<leader>yY", function()
  local path = vim.fn.expand("%:p")
  require("util.files").yank_absolute_path(path)
end, { desc = "Yank absolute path" })

vim.keymap.set("n", "<leader>yn", function()
  local path = vim.fn.expand("%:p")
  require("util.files").yank_file_name(path)
end, { desc = "Yank file name" })

vim.keymap.set("n", "<leader>yf", function()
  local path = vim.fn.expand("%:p")
  require("util.files").copy_files_to_clipboard { path }
end, { desc = "Copy file into system clipboard" })

-- Copy relative filename and pos
vim.keymap.set({ "n", "x" }, "<leader>l", function()
  local relative_path = vim.fn.expand("%:.")
  local mode = vim.fn.mode()
  local output = relative_path
  if mode ~= "v" and mode ~= "V" then
    local pos = vim.api.nvim_win_get_cursor(0)
    output = relative_path .. ":" .. pos[1]
  else
    local pos = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })

    ---@type [integer, integer, integer, integer] | nil, [integer, integer, integer, integer] | nil
    local start_pos, end_pos
    if #pos > 0 then
      start_pos = pos[1][1]
      end_pos = pos[#pos][2]
    end
    local range = ""
    if start_pos ~= nil and end_pos ~= nil then
      if mode == "V" then
        if start_pos[2] ~= end_pos[2] then
          range = string.format("%d-%d", start_pos[2], end_pos[2])
        else
          range = string.format("%d", start_pos[2])
        end
      elseif mode == "v" then
        if start_pos[2] ~= end_pos[2] or start_pos[3] ~= end_pos[3] then
          range = string.format("%d:%d-%d:%d", start_pos[2], start_pos[3], end_pos[2], end_pos[3])
        else
          range = string.format("%d:%d", start_pos[2], end_pos[3])
        end
      end
    end
    output = range ~= "" and (relative_path .. ":" .. range) or relative_path
  end
  vim.fn.setreg("+", output)
  vim.notify(output, vim.log.levels.INFO, { title = "Copied position", ft = "text" })
  -- deselecting visual selection if it's there
  local keys = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys, "nx", false)
end, {
  desc = "Copy filename:linenumber",
})

-- selecting previously pasted text, aka easier "`[v`]"
vim.keymap.set("n", "gp", function()
  return "`[" .. vim.fn.getregtype():sub(1, 1) .. "`]"
end, { expr = true, desc = "select last pasted text" })

-- delete/paste without a register
-- Paste without clipboard isn't really needed since nvim v0.8, where P in x
-- mode was introduced. I'm commenting it out to remember the "right way"
-- vim.keymap.set("x", "<leader>p", "P", { desc = "Paste w/o clipboard" })

vim.keymap.set("x", "x", '"_d', { desc = "Delete to blackhole" })

-- More sane exit terminal mode -- resembles Snacks terminal on <C-/ but
-- a single <Esc> now reaches programs after a timeoutlen outside of Snacks
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- scroll and center (defer zz until after animate scroll animation)
local function scroll_center(key)
  return function()
    local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
    vim.api.nvim_feedkeys(keys, "nx", false)
    vim.defer_fn(function()
      vim.cmd("normal! zz")
    end, 150)
  end
end

vim.keymap.set("n", "<C-u>", scroll_center("<C-u>"))
vim.keymap.set("n", "<C-d>", scroll_center("<C-d>"))

-- compatibility with vim-surround for mini.surrounding plugin -- for cyrillic as well
langmap.set_keymap("n", "ys", "gsa", { remap = true, desc = "Add surrounding" })
langmap.set_keymap("x", "S", "gsa", { remap = true, desc = "Add surrounding" })
langmap.set_keymap("n", "ds", "gsd", { remap = true, desc = "Delete surrounding" })
langmap.set_keymap("n", "cs", "gsr", { remap = true, desc = "Replace surrounding" })

-- Bufferline move buffers around and a shorter "pick buffer"
langmap.set_keymap("n", "<A-H>", "<cmd>BufferLineMovePrev<cr>")
langmap.set_keymap("n", "<A-L>", "<cmd>BufferLineMoveNext<cr>")
-- Duplicating move around for cyrillic specifically
vim.keymap.set("n", langmap.get("H"), "<cmd>BufferLineCyclePrev<cr>")
vim.keymap.set("n", langmap.get("L"), "<cmd>BufferLineCycleNext<cr>")
-- bufferline shorter keymaps for buffer selection:
langmap.set_keymap("n", "gb", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })
-- and "hydra" buffer pick close
local function hydra_pick_close()
  repeat
    local before = #vim.fn.getbufinfo { buflisted = 1 }
    vim.cmd("BufferLinePickClose")
    local after = #vim.fn.getbufinfo { buflisted = 1 }
  until after <= 1 or before == after
end
langmap.set_keymap("n", "gB", hydra_pick_close, { desc = "Pick Close Buffer" })
vim.keymap.set("n", "<Leader>bJ", hydra_pick_close, { desc = "Pick Close Buffer" })

-- Fake group to be filled in with our inline "Editing actions" plugins
require("which-key").add {
  {
    "<leader>j",
    group = "Editing actions",
    mode = { "n", "x" },
    icon = { cat = "extension", name = "txt" },
  },
}

vim.keymap.set("x", "<Leader>jw", ":<C-u>" .. table.concat({
  -- whitespace marker:
  [['<,'>s/·/ /ge]],
  -- leading tabs in ye olde vim (»···):
  [['<,'>s/^ *\zs\%(» *\)\+/\=repeat("\t", count(submatch(0), '»'))/e]],
  -- leading tabs in neovim (--->):
  [['<,'>s/^\%( *-*>\)\+/\=repeat("\t", count(submatch(0), '>'))/e]],
}, " | ") .. "<CR>", {
  desc = "replace ghost whitespaces copied in tmux",
  silent = true,
})

--------------------------------------------------------------------------------
-- Extra <leader>u? stuff

vim.keymap.set("n", "<leader>uW", function()
  vim.o.list = not vim.o.list
end, { desc = "Toggle whitespace display" })

-- Cookbook spell checks toggle
vim.keymap.set("n", "<leader>ue", function()
  if vim.lsp.is_enabled("codebook") then
    vim.lsp.enable("codebook", false)
    for i, v in pairs(vim.diagnostic.get_namespaces()) do
      if vim.startswith(v.name, "nvim.lsp.codebook") then
        -- we need to reset specific namespace to not break any other warning from LSP
        vim.diagnostic.reset(i)
        vim.diagnostic.hide(i)
      end
    end
    vim.notify("Disabled codebook", vim.log.levels.WARN, { title = "Spelling" })
  else
    vim.lsp.enable("codebook", true)
    vim.notify("Enabled codebook", { title = "Spelling" })
  end
end, { desc = "Toggle Codebook Sp[e]lling" })

-- Tear down snacks' doc-image attach state for a buffer (placements + autocmd
-- groups + attach flag) so the next doc.attach() re-renders from scratch.
-- NOTE: inline.new() registers an un-stored nvim_buf_attach(on_lines) with no
-- public detach, and inline:update() ignores config.doc.inline -- so switching
-- inline->float can re-show inline images on the next text edit. Reload the
-- buffer (:e) if it's acting up.
local function snacks_image_detach(buf)
  pcall(vim.api.nvim_del_augroup_by_name, "snacks.image.inline." .. buf)
  pcall(vim.api.nvim_del_augroup_by_name, "snacks.image.doc." .. buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.b[buf].snacks_image_attached = false
  end
end

vim.keymap.set("n", "<leader>uv", function()
  local doc = Snacks.image.doc
  local cfg = Snacks.image.config.doc
  cfg.inline = not cfg.inline
  cfg.float = true -- keep float as the fallback whenever inline is off

  local buf = vim.api.nvim_get_current_buf()
  doc.hover_close()
  Snacks.image.placement.clean(buf)
  snacks_image_detach(buf)
  doc.attach(buf)
  vim.notify("Doc images: " .. (cfg.inline and "inline" or "float"), vim.log.levels.INFO, { title = "Snacks image" })
end, { desc = "Toggle image inline/float render" })

vim.keymap.set("n", "<leader>uV", function()
  local cfg = Snacks.image.config
  cfg.enabled = not cfg.enabled
  Snacks.image.doc.hover_close()
  if cfg.enabled then
    -- re-attach current buffer; the FileType autocmd registered at setup handles
    -- any others as they're opened.
    local buf = vim.api.nvim_get_current_buf()
    snacks_image_detach(buf)
    Snacks.image.doc.attach(buf)
  else
    -- clear every buffer; doc.attach() now early-returns on enabled == false.
    Snacks.image.placement.clean()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      snacks_image_detach(buf)
    end
  end
  vim.notify("Image rendering: " .. (cfg.enabled and "on" or "off"), vim.log.levels.INFO, { title = "Snacks image" })
end, { desc = "Toggle image rendering" })

--------------------------------------------------------------------------------
-- Drop LazyVim's git-log binds: most are just shadowed by diffview, but gL we remove explicitly
-- vim.keymap.del("n", "<leader>gl") -- Git Log
vim.keymap.del("n", "<leader>gL") -- Git Log (CWD)
-- vim.keymap.del("n", "<leader>gb") -- Git Blame Line
-- vim.keymap.del("n", "<leader>gf") -- Git Current File History
vim.keymap.del({ "n", "x" }, "<leader>gY")
vim.keymap.set({ "n", "x" }, "<leader>gy", function()
  Snacks.gitbrowse {
    open = function(url)
      vim.fn.setreg("+", url)
      vim.notify(url, vim.log.levels.INFO, { title = "Github link" })
    end,
    notify = false,
  }
end, { desc = "Copy Github Line Link" })

-- Scratch buffers with a filetype
vim.keymap.set("n", "<leader>fm", "<cmd>enew | setlocal ft=markdown<cr>", { desc = "New Markdown Buffer" })
vim.keymap.set("n", "<leader>fj", "<cmd>enew | setlocal ft=json<cr>", { desc = "New JSON Buffer" })
