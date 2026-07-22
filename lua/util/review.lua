--- Lightweight review surface for diffview: drop line comments while reviewing a
--- diff, then export them all as markdown to hand to a coding agent.
---
--- Notes live in a plain in-memory list (source of truth for export). Inline
--- virtual text is best-effort session decoration via extmarks.
--- ponytail: extmarks are not re-rendered if diffview reopens/rebuilds its
--- buffers; the note list still exports fine. Add re-render on view_enter only
--- if losing the inline markers mid-review actually bites.

local M = {}

--- @class ReviewNote
--- @field file string   repo-relative path
--- @field line integer  1-based line in that file's shown side
--- @field side "old"|"new"
--- @field text string

--- @type ReviewNote[]
M.notes = {}

local ns = vim.api.nvim_create_namespace("review_notes")

--- Resolve file + line + side under the cursor. Prefers the diffview entry (so
--- the path is repo-relative and the a/b side is known); falls back to the plain
--- current buffer for reviewing outside diffview.
--- @return { file: string, line: integer, side: "old"|"new", bufnr: integer }|nil
local function locate()
  local win = vim.api.nvim_get_current_win()
  local ok, lib = pcall(require, "diffview.lib")
  local view = ok and lib.get_current_view()
  local entry = view and view.cur_entry
  if entry then
    -- Default to the new side; only call it "old" when the cursor is in the a-win.
    local side, file = "new", entry.path
    if entry.layout and entry.layout.a and entry.layout.a.id == win then
      side, file = "old", entry.oldpath or entry.path
    end
    return { file = file, line = vim.fn.line("."), side = side, bufnr = vim.api.nvim_win_get_buf(win) }
  end
  -- Plain buffer: only real, named files (skip terminals, pickers, scratch).
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
    return nil
  end
  return { file = vim.fn.expand("%:."), line = vim.fn.line("."), side = "new", bufnr = buf }
end

--- Find an existing note anchored at the same file/line/side as `loc`.
--- @return integer|nil idx, ReviewNote|nil note
local function find_note(loc)
  for i, n in ipairs(M.notes) do
    if n.file == loc.file and n.line == loc.line and n.side == loc.side then
      return i, n
    end
  end
end

--- Inline marker: first line + an ellipsis when the note spans more.
local function set_mark(bufnr, line, text)
  local first = vim.split(text, "\n")[1]
  local more = text:find("\n") and " …" or ""
  vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
    virt_text = { { "  💬 " .. first .. more, "Comment" } },
    virt_text_pos = "eol",
  })
end

--- Floating multi-line editor. Insert to type, <C-s> (any mode) or <CR> (normal)
--- to save, q/<esc> (normal) to cancel. Submits the trimmed text via on_submit.
local function open_float(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  local lines = opts.text ~= "" and vim.split(opts.text, "\n") or { "" }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = math.min(80, math.max(40, vim.o.columns - 20))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(12, math.max(3, #lines + 1)),
    style = "minimal",
    border = "rounded",
    title = opts.title or " note (leave to save · q cancels) ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true

  -- Commit-on-leave: closing the float any way (save key, :q, focus elsewhere)
  -- saves, unless a cancel key set the flag first. One save only, guarded.
  local cancelled, done = false, false
  local function commit()
    if done then
      return
    end
    done = true
    if cancelled then
      return
    end
    opts.on_submit(vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")))
  end
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.api.nvim_create_autocmd({ "WinLeave", "BufWinLeave" }, {
    buffer = buf,
    once = true,
    callback = function()
      commit()
      vim.schedule(close)
    end,
  })
  local function cancel()
    cancelled = true
    close()
  end
  vim.keymap.set({ "n", "i" }, "<C-s>", close, { buffer = buf, desc = "Save note" })
  vim.keymap.set("n", "<CR>", close, { buffer = buf, desc = "Save note" })
  vim.keymap.set("n", "q", cancel, { buffer = buf, desc = "Cancel note" })
  vim.keymap.set("n", "<esc>", cancel, { buffer = buf, desc = "Cancel note" })
  vim.cmd("startinsert")
end

--- Add a note on the current line, or edit the one already there. Emptying the
--- text deletes the note.
function M.add()
  local loc = locate()
  if not loc then
    vim.notify("review: no file under cursor", vim.log.levels.WARN)
    return
  end
  local idx, existing = find_note(loc)
  open_float {
    title = existing and " edit note · leave saves, q cancels " or " new note · leave saves, q cancels ",
    text = existing and existing.text or "",
    on_submit = function(text)
      vim.api.nvim_buf_clear_namespace(loc.bufnr, ns, loc.line - 1, loc.line)
      if text == "" then
        if idx then
          table.remove(M.notes, idx)
        end
        return
      end
      local note = { file = loc.file, line = loc.line, side = loc.side, text = text }
      if idx then
        M.notes[idx] = note
      else
        table.insert(M.notes, note)
      end
      set_mark(loc.bufnr, loc.line, text)
    end,
  }
end

--- Render all notes as markdown.
--- @return string
function M.to_markdown()
  if #M.notes == 0 then
    return "No review notes.\n"
  end
  -- Stable order: group by file, then by line.
  local sorted = vim.deepcopy(M.notes)
  table.sort(sorted, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    return a.line < b.line
  end)
  local out = { "# Review notes\n" }
  local cur_file = nil
  for _, n in ipairs(sorted) do
    if n.file ~= cur_file then
      cur_file = n.file
      out[#out + 1] = "\n## `" .. n.file .. "`\n"
    end
    local body = vim.split(n.text, "\n")
    out[#out + 1] = ("- **%s:%d** (%s): %s"):format(n.file, n.line, n.side, body[1])
    for i = 2, #body do
      out[#out + 1] = "  " .. body[i]
    end
  end
  out[#out + 1] = ""
  return table.concat(out, "\n")
end

--- Export notes to a scratch markdown buffer and copy them to the + register.
function M.export()
  local md = M.to_markdown()
  vim.fn.setreg("+", md)
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(md, "\n"))
  vim.notify(("review: exported %d note(s), copied to clipboard"):format(#M.notes))
end

--- Jump to the next (dir=1) or previous (dir=-1) note in the current buffer,
--- wrapping around. Uses live extmark positions, so it tracks both diffview and
--- plain buffers and survives line shifts.
function M.jump(dir)
  local buf = vim.api.nvim_get_current_buf()
  local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
  if #marks == 0 then
    vim.notify("review: no notes in this buffer", vim.log.levels.INFO)
    return
  end
  local rows = {}
  for _, m in ipairs(marks) do
    rows[#rows + 1] = m[2] -- 0-based row
  end
  table.sort(rows)
  local cur = vim.api.nvim_win_get_cursor(0)[1] - 1
  local target
  if dir > 0 then
    for _, r in ipairs(rows) do
      if r > cur then
        target = r
        break
      end
    end
    target = target or rows[1]
  else
    for i = #rows, 1, -1 do
      if rows[i] < cur then
        target = rows[i]
        break
      end
    end
    target = target or rows[#rows]
  end
  vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
end

--- Drop all notes and clear inline markers from listed buffers.
function M.clear()
  M.notes = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end
  vim.notify("review: cleared")
end

return M
