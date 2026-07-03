-- Observable Framework markdown: highlight ${ ... } inline JS interpolations.
-- https://observablehq.com/documentation/cells/markdown#adding-dynamic-values
-- This is a shot from a slop cannon, I don't want to spend any time fighting
-- tree-sitter for this thing.
--
-- In an Observable `.md` page, `${expr}` embeds an arbitrary (often multi-line)
-- JavaScript expression. tree-sitter-markdown has no node for it: the whole
-- `<div>...</div>` becomes one opaque `html_block`, into which the `html`
-- parser is injected (combined, over the block's full text). That parser then
-- chokes on the JS (`{`, `=>`, `}`), derails into ERROR nodes, and stops
-- highlighting html for the rest of the block (and file).
--
-- Two overrides in queries/markdown/injections.scm fix this:
--   1. javascript is injected into each `${...}` (so the JS highlights), and
--   2. the default html_block->html injection is replaced with one that carves
--      the `${...}` spans *out*, feeding html only the JS-free fragments so it
--      no longer derails.
--
-- Neither `${}` nor the html-only gaps are tree-sitter nodes, so both are driven
-- by directives here. The vehicle: every non-first line of an html_block carries
-- a `block_continuation` node, and the html_block node itself stands in for the
-- first line -- so we anchor per line and compute, per line, either the JS range
-- (js injection) or the html-only range (html injection). Combined injection
-- merges the html fragments back into one clean html parse.
--
-- brace counting is string-unaware -- an unbalanced brace inside a JS
-- string literal (e.g. `"}"`) mis-closes. And a line with html on *both* sides
-- of a single-line `${x}` (inline prose) collapses to no-html; such prose lives
-- in `inline` nodes (markdown_inline injection), not html_block, so it's moot
-- here. Upgrade to a real tokenizer only if either bites.

local ts = vim.treesitter

-- Scan from the char after a `${`'s `{` for the matching `}`.
-- `lines` is 0-indexed via row+1; `row`/`col` are 0-indexed. Returns the
-- 0-indexed (row, col) of the closing `}`, or nil if unbalanced.
local function scan_close(lines, row, col)
  local depth = 1
  while row < #lines do
    local line = lines[row + 1]
    local i = col
    while i < #line do
      local ch = line:sub(i + 1, i + 1)
      if ch == "{" then
        depth = depth + 1
      elseif ch == "}" then
        depth = depth - 1
        if depth == 0 then
          return row, i
        end
      end
      i = i + 1
    end
    row, col = row + 1, 0
  end
end

-- All top-level `${...}` inside an html_block, as absolute 0-indexed spans:
-- { inner = {srow,scol,erow,ecol}, outer = {srow,scol,erow,ecol} } where inner
-- is the JS between `${` and `}`, and outer includes the `${` and `}` delimiters.
local function scan_block(bufnr, html_block)
  local b_srow, _, b_erow = html_block:range()
  local lines = vim.api.nvim_buf_get_lines(bufnr, b_srow, b_erow + 1, false)
  local interps = {}
  local row, col = 0, 0
  while row < #lines do
    local line = lines[row + 1]
    local s = line:find("%${", col + 1) -- 1-indexed position of `$`
    if s then
      local inner_scol = s + 1 -- 0-indexed col just past `{`
      local crow, ccol = scan_close(lines, row, inner_scol)
      if crow then
        interps[#interps + 1] = {
          inner = { b_srow + row, inner_scol, b_srow + crow, ccol },
          outer = { b_srow + row, s - 1, b_srow + crow, ccol + 1 },
        }
        row, col = crow, ccol + 1
      else
        break -- unterminated; give up on the rest of the block
      end
    else
      row, col = row + 1, 0
    end
  end
  return interps
end

-- Memoize the scan per block within one (buffer, changedtick): a full
-- re-highlight hits every anchor, and both languages' predicates+directives
-- need the same scan. Wiping on tick change keeps it bounded.
local cache = { bufnr = nil, tick = nil, blocks = {} }
local function block_of(node)
  if node:type() == "html_block" then
    return node
  end
  local parent = node:parent()
  return parent and parent:type() == "html_block" and parent or nil
end
local function interps_for(bufnr, node)
  local html_block = block_of(node)
  if not html_block then
    return nil
  end
  local tick = vim.b[bufnr].changedtick
  if cache.bufnr ~= bufnr or cache.tick ~= tick then
    cache.bufnr, cache.tick, cache.blocks = bufnr, tick, {}
  end
  local brow = html_block:range()
  local hit = cache.blocks[brow]
  if not hit then
    hit = scan_block(bufnr, html_block)
    cache.blocks[brow] = hit
  end
  return hit
end

-- The inner JS range of the interpolation that *opens* on this anchor's line.
local function js_range(bufnr, node)
  local nrow = node:range()
  local interps = interps_for(bufnr, node)
  for _, it in ipairs(interps or {}) do
    if it.inner[1] == nrow then
      return it.inner
    end
  end
end

-- The html-only span of this anchor's line: the whole line minus any `${...}`
-- covering it. nil when the line is entirely inside an interpolation.
local function html_range(bufnr, node)
  local interps = interps_for(bufnr, node)
  if not interps then
    return nil
  end
  local row = node:range()
  local line = (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false))[1] or ""
  local left, right = 0, #line
  for _, it in ipairs(interps) do
    local o = it.outer
    if o[1] < row and row < o[3] then
      return nil -- line is in the interior of a multi-line interpolation
    end
    if row == o[1] then
      right = math.min(right, o[2]) -- interpolation opens here: html is before it
    end
    if row == o[3] then
      left = math.max(left, o[4]) -- interpolation closes here: html is after it
    end
  end
  if left >= right then
    return nil
  end
  return { row, left, row, right }
end

local function make_pair(name, range_fn)
  -- all=true so match[id] is a list of nodes (we take the first).
  ts.query.add_predicate(name .. "?", function(match, _, bufnr, pred)
    local node = match[pred[2]] and match[pred[2]][1]
    return node ~= nil and range_fn(bufnr, node) ~= nil
  end, { force = true, all = true })

  ts.query.add_directive(name .. "!", function(match, _, bufnr, pred, metadata)
    local id = pred[2]
    local node = match[id] and match[id][1]
    local r = node and range_fn(bufnr, node)
    if r then
      metadata[id] = metadata[id] or {}
      metadata[id].range = r
    end
  end, { force = true, all = true })
end

make_pair("obs-js", js_range)
make_pair("obs-html", html_range)
