--- utils for obsidian vault detection and frontmatter templates
local M = {}

M.workspaces = {
  {
    name = "obsidian",
    path = "~/Documents/obsidian/",
  },
}

-- Obsidian-style template that uses {{date}} / {{time}} / {{title}} mustache vars
M.template_path = "~/Documents/obsidian/templates/frontmatter.md"

--- Translate the (common subset of) moment.js format tokens that Obsidian uses
--- into os.date / strftime tokens. Longest tokens first so e.g. YYYY is matched
--- before YY.
---@param fmt string moment.js format string, e.g. "YYYY-MM-DD"
---@return string strftime format string
local function moment_to_strftime(fmt)
  -- `A` (AM/PM) is first on purpose: the strftime tokens we emit contain letters
  -- (e.g. dddd -> %A), so a trailing single-char `A` sub would clobber them.
  -- Moment input never contains `%` or a stray `A`, so matching it first is safe.
  local subs = {
    { "A", "%%p" },
    { "YYYY", "%%Y" },
    { "MMMM", "%%B" },
    { "dddd", "%%A" },
    { "MMM", "%%b" },
    { "ddd", "%%a" },
    { "YY", "%%y" },
    { "MM", "%%m" },
    { "DD", "%%d" },
    { "HH", "%%H" },
    { "hh", "%%I" },
    { "mm", "%%M" },
    { "ss", "%%S" },
  }
  for _, s in ipairs(subs) do
    fmt = fmt:gsub(s[1], s[2])
  end
  return fmt
end

--- Render Obsidian-style {{...}} template variables in a single line.
--- Supports {{date}}, {{time}}, {{title}} and the {{date:FORMAT}} /
--- {{time:FORMAT}} variants (FORMAT being moment.js tokens).
---@param str string
---@param ctx? { title?: string } extra substitution context
---@return string
local function render_template(str, ctx)
  ctx = ctx or {}
  str = str:gsub("{{date:([^}]*)}}", function(fmt)
    return os.date(moment_to_strftime(fmt))
  end)
  str = str:gsub("{{time:([^}]*)}}", function(fmt)
    return os.date(moment_to_strftime(fmt))
  end)
  str = str:gsub("{{date}}", function()
    return os.date("%Y-%m-%d")
  end)
  str = str:gsub("{{time}}", function()
    return os.date("%H:%M")
  end)
  str = str:gsub("{{title}}", function()
    return ctx.title or ""
  end)
  return str
end

--- Return the workspace that contains the given buffer's file, or nil.
---@param bufnr? integer defaults to current buffer
---@return { name: string, path: string }|nil
function M.get_vault(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  if path == "" then
    return nil
  end
  for _, ws in ipairs(M.workspaces) do
    if vim.startswith(path, vim.fn.expand(ws.path)) then
      return ws
    end
  end
  return nil
end

--- Paths of every configured vault, for pickers that take a `dirs` list.
--- Left unexpanded -- snacks normalizes (and expands ~) on its own.
---@return string[]
function M.vault_paths()
  return vim
    .iter(M.workspaces)
    :map(function(ws)
      return ws.path
    end)
    :totable()
end

--- Read the frontmatter template and render its variables.
---@param ctx? { title?: string }
---@return string[]|nil lines or nil if the template can't be read
function M.get_frontmatter(ctx)
  local tpl = vim.fn.expand(M.template_path)
  local ok, lines = pcall(vim.fn.readfile, tpl)
  if not ok then
    vim.notify("obsidian: cannot read template " .. tpl, vim.log.levels.ERROR)
    return nil
  end
  return vim
    .iter(lines)
    :map(function(l)
      return render_template(l, ctx)
    end)
    :totable()
end

--- Insert the rendered frontmatter template at the top of the buffer.
---@param bufnr? integer defaults to current buffer
function M.insert_frontmatter(bufnr)
  bufnr = bufnr or 0
  local title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t:r")
  local lines = M.get_frontmatter { title = title }
  if not lines then
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
end

return M
