-- Clean up CLI drawboxes in markdown: tables drawn by claude or duckdb.
-- Plain config, not a plugin spec: creating the command is cheap and its body
-- only runs on invocation, so there's nothing to lazy-load.
vim.api.nvim_create_user_command("MarkdownTableFromBox", function(opts)
  -- Delete table top and bottom borders first
  vim.cmd(opts.line1 .. "," .. opts.line2 .. [[ g/\s*[┌└][─┬┴]*[┐┘]/d _]])
  -- Re-clamp range since deletions may have shifted/shrunk it
  local last = vim.fn.line("$")
  local l1 = math.min(opts.line1, last)
  local l2 = math.min(opts.line2, last)

  if l1 > l2 then
    return
  end
  local range = l1 .. "," .. l2
  vim.cmd(range .. [[ s/[├┼┤│]/|/g ]])
  vim.cmd(range .. [[ s/─/-/g ]])

  local search_pattern = [[^\s*|\(-*|\)\+\s*$]]
  -- move cursor to the start of the range, so search will work
  vim.fn.cursor(l1, 1)
  local first_match = vim.fn.search(search_pattern, "n", l2)

  if first_match > 0 and first_match < l2 then
    range = (first_match + 1) .. "," .. l2
    vim.cmd(range .. "g/" .. search_pattern .. "/d _")
  end
end, { range = true, desc = "Remove box-drawing chars" })

-- Split a markdown table row into trimmed cells, dropping the outer pipes.
-- does not handle escaped `\|` inside cells
local function parse_row(line)
  line = vim.trim(line):gsub("^|", ""):gsub("|$", "")
  local cells = {}
  for cell in (line .. "|"):gmatch("(.-)|") do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

-- A markdown separator row is all `:?-+:?` cells, e.g. `|---|:--:|`.
local function is_separator(cells)
  for _, c in ipairs(cells) do
    if not c:match("^:?%-+:?$") then
      return false
    end
  end
  return #cells > 0
end

-- Alignment encoded by the `:` markers on a separator cell: `:--`=left,
-- `--:`=right, `:--:`=center, `---`=left (default).
local function cell_align(c)
  local l, r = c:sub(1, 1) == ":", c:sub(-1) == ":"
  if l and r then
    return "center"
  elseif r then
    return "right"
  end
  return "left"
end

-- Markdown pipe table -> box-drawing table.
vim.api.nvim_create_user_command("MarkdownTableToBox", function(opts)
  local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)

  -- Parse rows, remembering where the header separator sat so we can redraw it
  -- and capturing per-column alignment from its `:` markers.
  local rows, sep_after, aligns = {}, nil, {}
  for _, line in ipairs(lines) do
    if vim.trim(line) ~= "" then
      local cells = parse_row(line)
      if is_separator(cells) then
        sep_after = #rows -- divider goes after this many leading rows
        for c, cell in ipairs(cells) do
          aligns[c] = cell_align(cell)
        end
      else
        rows[#rows + 1] = cells
      end
    end
  end

  if #rows == 0 then
    vim.notify("MarkdownTableToBox: no table rows in selection", vim.log.levels.WARN)
    return
  end

  -- Normalize column count and compute per-column display widths.
  local ncols = 0
  for _, r in ipairs(rows) do
    ncols = math.max(ncols, #r)
  end
  local widths = {}
  for c = 1, ncols do
    local w = 0
    for _, r in ipairs(rows) do
      w = math.max(w, vim.fn.strdisplaywidth(r[c] or ""))
    end
    widths[c] = w
  end

  local function border(left, mid, right)
    local segs = {}
    for c = 1, ncols do
      segs[c] = string.rep("─", widths[c] + 2)
    end
    return left .. table.concat(segs, mid) .. right
  end

  local function data_row(r)
    local parts = {}
    for c = 1, ncols do
      local cell = r[c] or ""
      local pad = widths[c] - vim.fn.strdisplaywidth(cell)
      local lp, rp = 0, pad -- left-align (default)
      if aligns[c] == "right" then
        lp, rp = pad, 0
      elseif aligns[c] == "center" then
        lp = math.floor(pad / 2)
        rp = pad - lp
      end
      parts[c] = " " .. string.rep(" ", lp) .. cell .. string.rep(" ", rp) .. " "
    end
    return "│" .. table.concat(parts, "│") .. "│"
  end

  local out = { border("┌", "┬", "┐") }
  for i, r in ipairs(rows) do
    out[#out + 1] = data_row(r)
    if sep_after and i == sep_after then
      out[#out + 1] = border("├", "┼", "┤")
    end
  end
  out[#out + 1] = border("└", "┴", "┘")

  vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, out)
end, { range = true, desc = "Markdown table -> box table" })

vim.keymap.set("x", "<leader>jt", ":<C-u>'<,'>MarkdownTableFromBox<CR>", {
  desc = "Clean out box-drawing characters",
})
vim.keymap.set("x", "<leader>jT", ":<C-u>'<,'>MarkdownTableToBox<CR>", {
  desc = "Markdown table to box-drawing table",
})
