-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- mapping <C-space> to noop, so we can switch keyboard layouts with it not affecting anything else
-- incremental treesitter is on S, see ../plugins/override_flash.lua:11
vim.keymap.set({ "n", "o", "x", "i" }, "<C-space>", "<nop>", { noremap = true })
-- insert mode: the terminal sends <C-space> as <C-@>, which triggers the
-- builtin i_CTRL-@ ("insert last inserted text + stop insert")
vim.keymap.set("i", "<C-@>", "<nop>", { noremap = true })

-- $ in visual mode is stupid, as it selects trailing CR, as well. remapping to g_
vim.keymap.set("x", "$", "g_")

-- helix-like combinations for start-end of the line on the home row
vim.keymap.set({ "n", "o", "x" }, "gh", "^")
vim.keymap.set({ "n", "o", "x" }, "пр", "^")
vim.keymap.set({ "n", "o", "x" }, "gH", "0")
vim.keymap.set({ "n", "o", "x" }, "пР", "0")
vim.keymap.set({ "n", "o", "x" }, "gl", "g_")
vim.keymap.set({ "n", "o", "x" }, "пд", "g_")

-- move record macro to <C-q> from just q, as I apparently constantly hit q by accident
vim.keymap.set("n", "<C-q>", "q", { noremap = true, desc = "Record macro" })
vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("n", "й", "<nop>", { noremap = true })

vim.keymap.set("i", "<C-в>", "<Delete>")
vim.keymap.set("i", "<C-d>", "<Delete>", { desc = "Delete forward" })
vim.keymap.set("i", "<C-ы>", "<C-o>dw")
vim.keymap.set("i", "<C-s>", "<C-o>dw", { desc = "Delete forward word" })
vim.keymap.set("i", "<C-ц>", "<C-w>")
-- Vim normally uses C-d in insert mode to decrease indent, but this conflicts with our delete binding
-- So let's switch that to <C-y> which normally is a useless "Insert the character which is above the cursor."
vim.keymap.set("i", "<C-y>", "<C-o><<", { silent = true })
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
-- A lot of stuff for cut/paste without register
vim.keymap.set("x", "<leader>p", "pgvy", { desc = "Paste w/o clipboard" })

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

vim.keymap.set("x", "x", '"_d', { desc = "Delete to blackhole" })
vim.keymap.set({ "n", "v", "o" }, "<LocalLeader>d", '"_d', { desc = "Delete to blackhole" })

-- More sane exit terminal mode -- doesn't work on MacOS
vim.keymap.set("t", "<C-Esc>", "<C-\\><C-n>", { remap = true, desc = "Exit terminal mode" })
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

-- compatibility with vim-surround for mini.surrounding plugin
vim.keymap.set("n", "ys", "gsa", { remap = true, desc = "Add surrounding" })
vim.keymap.set("n", "ds", "gsd", { remap = true, desc = "Delete surrounding" })
vim.keymap.set("n", "cs", "gsr", { remap = true, desc = "Replace surrounding" })
vim.keymap.set("x", "S", "gsa", { remap = true, desc = "Add surrounding" })

-- Bufferline move buffers around and a shorter "pick buffer"
vim.keymap.set("n", "<A-H>", "<cmd>BufferLineMovePrev<cr>")
vim.keymap.set("n", "<A-L>", "<cmd>BufferLineMoveNext<cr>")
-- Cyrillic versions of that
vim.keymap.set("n", "<A-Р>", "<cmd>BufferLineMovePrev<cr>")
vim.keymap.set("n", "<A-Д>", "<cmd>BufferLineMoveNext<cr>")
-- And to move around
vim.keymap.set("n", "Р", "<cmd>BufferLineCyclePrev<cr>")
vim.keymap.set("n", "Д", "<cmd>BufferLineCycleNext<cr>")
-- bufferline shorter keymaps for buffer selection:
vim.keymap.set("n", "gb", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })
-- and "hydra" buffer pick close
local function hydra_pick_close()
  repeat
    local before = #vim.fn.getbufinfo { buflisted = 1 }
    vim.cmd("BufferLinePickClose")
    local after = #vim.fn.getbufinfo { buflisted = 1 }
  until after <= 1 or before == after
end
vim.keymap.set("n", "gB", hydra_pick_close, { desc = "Pick Close Buffer" })
vim.keymap.set("n", "<Leader>bJ", hydra_pick_close, { desc = "Pick Close Buffer" })
-- Fake group to be filled in with our inline plugins
require("which-key").add {
  {
    "<leader>j",
    group = "Editing actions",
    mode = { "n", "x" },
    icon = { cat = "extension", name = "txt" },
  },
}

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
end, { desc = "Toggle image rendering on/off" })
