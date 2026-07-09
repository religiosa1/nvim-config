-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disabling builtin-in spellchecker in favor of codebook for:
-- "text", "plaintex", "typst", "gitcommit", "markdown
-- pcall: the group only exists on first load, so a manual :luafile re-source
-- of this file would otherwise error here and skip everything below.
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  desc = "Enabling wrapping back for plainish text buffers",
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- vim.lsp.document_color.color_presentation() for switching between gex and rgb, etc
-- Doing it in autocmd to avoid eagerly loading the full LSP thing
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Enable vscode-style color markers thorugh lsp",
  once = true,
  callback = function()
    vim.lsp.document_color.enable(true, nil, { style = "virtual" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "extra grug-far functionality",
  pattern = { "grug-far" },
  callback = function(args)
    local buf_id = args.buf
    -- we need to schedule, as grug-far sets the option to none on buf setup
    vim.schedule(function()
      vim.bo[buf_id].buftype = "acwrite"
      -- also need a name for the buffer, or :w will complain
      if vim.api.nvim_buf_get_name(buf_id) == "" then
        vim.api.nvim_buf_set_name(buf_id, "grug-far://" .. buf_id)
      end

      vim.api.nvim_create_autocmd("BufWriteCmd", {
        desc = "syncing grug-far on write",
        buffer = buf_id,
        callback = function()
          -- checking we're in the grug-far buffer, so it won't randomly sync on :wall
          if vim.api.nvim_get_current_buf() == buf_id then
            require("grug-far").get_instance(0):sync_all()
          end
          vim.bo[buf_id].modified = false
        end,
      })
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        desc = "resetting grug-far modified flag back, so it doesn't bother us with confirmations",
        buffer = buf_id,
        callback = function()
          vim.bo[buf_id].modified = false
        end,
      })
    end)
  end,
})

-- Slop <details>...</details> fold  blocks in markdown, initially closed.
-- LazyVim keeps treesitter as the fold provider (folds sections/code), but the
-- markdown parser emits <details> and </details> as two *separate* html_blocks,
-- so it never folds the body between them. Compose on top of the treesitter
-- foldexpr: raise the fold level by the number of currently-open <details>
-- blocks. The <summary> line stays visible and becomes the fold's foldtext.
do
  -- depth[lnum] = how many <details> bodies are open at that line. Cached per
  -- buffer changedtick so the foldexpr stays O(n) total instead of O(n^2).
  -- The body is everything *after* </summary> through </details>, so the
  -- <details> and <summary> lines stay visible and only the body folds.
  local cache = {}
  local function details_depth(buf)
    local tick = vim.b[buf].changedtick
    local c = cache[buf]
    if c and c.tick == tick then
      return c.depth
    end
    local depth, open = {}, 0
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      -- Record openness before mutating: the </summary> line stays at base
      -- (raise starts on the next line); the </details> line stays raised (it
      -- belongs to the fold) and drops the level afterwards.
      depth[i] = open
      if line:match("</summary>") then
        open = open + 1
      elseif line:match("^%s*</details>") then
        open = math.max(open - 1, 0)
      end
    end
    cache[buf] = { tick = tick, depth = depth }
    return depth
  end

  function _G.MarkdownDetailsFoldexpr()
    local lnum = vim.v.lnum
    local base = vim.treesitter.foldexpr(lnum)
    local depth = details_depth(vim.api.nvim_get_current_buf())[lnum] or 0
    if depth == 0 then
      return base
    end
    -- base is a plain number for markdown, but keep any ">"/"<" marker
    -- treesitter might emit and just bump the numeric part.
    local marker, num = tostring(base):match("^([<>]?)(%-?%d+)$")
    if not num then
      return base
    end
    return marker .. tostring(tonumber(num) + depth)
  end

  -- foldlevel is 99 (everything open by default), so close the details folds
  -- once. Run in the target window so foldclose acts on the right folds.
  local function close_details(buf, win)
    if not (vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf) then
      return
    end
    vim.api.nvim_win_call(win, function()
      for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if line:match("</summary>") then
          pcall(vim.cmd, string.format("%dfoldclose", i + 1))
        end
      end
    end)
  end

  local function activate(win, buf)
    if vim.bo[buf].filetype ~= "markdown" then
      return
    end
    -- window-local, set on every display so it stays ahead of LazyVim's
    -- treesitter foldexpr default (also covers the buffer shown in a 2nd window).
    vim.wo[win].foldexpr = "v:lua.MarkdownDetailsFoldexpr()"
    if vim.b[buf].details_folds_closed then
      return
    end
    vim.b[buf].details_folds_closed = true
    -- schedule so folds recompute against the foldexpr just set above; closing
    -- while LazyVim's default is still active would collapse the whole section.
    vim.schedule(function()
      close_details(buf, win)
    end)
  end

  vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "Enable markdown details folds",
    pattern = { "markdown" },
    callback = function(args)
      activate(vim.api.nvim_get_current_win(), args.buf)
    end,
  })

  -- config.autocmds loads on VeryLazy, *after* a file opened at startup already
  -- fired BufWinEnter, so activate any markdown windows that are already open.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    activate(win, vim.api.nvim_win_get_buf(win))
  end
end
