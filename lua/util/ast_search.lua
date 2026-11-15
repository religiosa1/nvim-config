--- ast-grep search in the current buffer, behaving like `/`.
--- Matches are converted into a position-based vim regex and put into the
--- search register, so n/N, hlsearch and search count work natively.
--- NOTE: positions are static — after edits that shift text, re-run the search.
local M = {}

local preview_ns = vim.api.nvim_create_namespace("ast_search_preview")

-- filetypes whose names differ from ast-grep language names
local lang_by_filetype = {
  sh = "bash",
  cs = "csharp",
  javascriptreact = "javascript",
  typescriptreact = "tsx",
}

---Converts a 0-based byte offset into a 1-based {line, byte column}.
---@param line_starts integer[] 0-based byte offset of each line start
---@param offset integer
local function offset_to_pos(line_starts, offset)
  local lo, hi = 1, #line_starts
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    if line_starts[mid] <= offset then
      lo = mid
    else
      hi = mid - 1
    end
  end
  return lo, offset - line_starts[lo] + 1
end

---@class AstSearchMatch
---@field start_line integer 1-based
---@field start_col integer 1-based byte column
---@field end_line integer
---@field end_col integer exclusive

---@param buf integer
---@param pattern string ast-grep pattern
---@return AstSearchMatch[]? matches
---@return string? err
local function find(buf, pattern)
  local ft = vim.bo[buf].filetype
  local lang = lang_by_filetype[ft] or ft
  if lang == "" then
    return nil, "buffer has no filetype"
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local line_starts, offset = {}, 0
  for i, line in ipairs(lines) do
    line_starts[i] = offset
    offset = offset + #line + 1
  end

  local result = vim
    .system({ "ast-grep", "run", "--pattern", pattern, "--lang", lang, "--stdin", "--json=stream" }, {
      stdin = table.concat(lines, "\n") .. "\n",
    })
    :wait()
  if result.stderr ~= "" then
    return nil, vim.trim(result.stderr)
  end

  local matches = {}
  for json in result.stdout:gmatch("[^\n]+") do
    local bytes = vim.json.decode(json).range.byteOffset
    local match = {}
    match.start_line, match.start_col = offset_to_pos(line_starts, bytes.start)
    match.end_line, match.end_col = offset_to_pos(line_starts, bytes["end"])
    matches[#matches + 1] = match
  end
  return matches
end

---Highlights matches while the pattern is being typed, like 'incsearch'.
local function preview(buf, pattern)
  vim.api.nvim_buf_clear_namespace(buf, preview_ns, 0, -1)
  -- partial patterns are often invalid; just show nothing for them
  local matches = pattern ~= "" and find(buf, pattern) or {}
  for _, match in ipairs(matches or {}) do
    vim.api.nvim_buf_set_extmark(buf, preview_ns, match.start_line - 1, match.start_col - 1, {
      end_row = match.end_line - 1,
      end_col = match.end_col - 1,
      hl_group = "Search",
      strict = false,
    })
  end
  vim.cmd.redraw()
end

---@param pattern string ast-grep pattern
---@param backward? boolean
function M.search(pattern, backward)
  local matches, err = find(vim.api.nvim_get_current_buf(), pattern)
  if not matches then
    vim.notify(err, vim.log.levels.ERROR, { title = "ast-grep" })
    return
  end
  if #matches == 0 then
    vim.notify("ast-grep: pattern not found: " .. pattern, vim.log.levels.WARN)
    return
  end

  local branches = vim.tbl_map(function(match)
    return string.format(
      [[\%%%dl\%%%dc\_.\{-}\%%%dl\%%%dc]],
      match.start_line,
      match.start_col,
      match.end_line,
      match.end_col
    )
  end, matches)
  vim.fn.setreg("/", [[\m]] .. table.concat(branches, [[\|]]))
  vim.v.searchforward = backward and 0 or 1
  vim.cmd("silent normal! n")
end

---@param backward? boolean
function M.prompt(backward)
  local buf = vim.api.nvim_get_current_buf()
  local preview_autocmd = vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = "@", -- input() cmdline type
    callback = function()
      preview(buf, vim.fn.getcmdline())
    end,
  })

  -- syntax cheatsheet; noice shows prompts <= 60 bytes as the popup title
  local hint = "$A node; $$$ 0+; $_ no capture"
  local prompt = string.format("ast-grep%s %s", backward and "?" or "/", hint)
  local ok, pattern = pcall(vim.fn.input, { prompt = prompt, cancelreturn = "" })
  vim.api.nvim_del_autocmd(preview_autocmd)
  vim.api.nvim_buf_clear_namespace(buf, preview_ns, 0, -1)
  if ok and pattern ~= "" then
    M.search(pattern, backward)
  end
end

return M
