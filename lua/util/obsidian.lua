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

-- Shared snacks picker opts: search the first vault by default, with <a-w>
-- toggling to search across every configured vault.
local function vault_scope_opts()
  return {
    dirs = { M.workspaces[1].path },
    toggles = { all_vaults = "w" },
    actions = {
      toggle_vaults = function(picker)
        picker.opts.all_vaults = not picker.opts.all_vaults
        picker.opts.dirs = picker.opts.all_vaults and M.vault_paths() or { M.workspaces[1].path }
        picker.list:set_target()
        picker:find()
      end,
    },
    win = {
      input = {
        keys = {
          ["<a-w>"] = { "toggle_vaults", mode = { "i", "n" }, desc = "Toggle all vaults" },
        },
      },
    },
  }
end

---Open a picker, that searches a note by name
function M.find_note()
  Snacks.picker.files(vim.tbl_deep_extend("force", vault_scope_opts(), {
    live = true, -- setting live for case-insensitive non-latin search
  }))
end

---Open a picker, that searches a note by text entry
function M.grep_note()
  Snacks.picker.grep(vault_scope_opts())
end

---Create a new note.
---Creates a new note in the current workspace, or in the first workspace if
---we're outside of any workspace.
function M.new_note()
  Snacks.input.input({
    prompt = "Enter note name",
    completion = "file",
  }, function(value)
    local name = value and vim.trim(value) or ""
    if name == "" then
      return
    end
    -- create relative to the current vault if we're in one, else the first
    local ws = M.get_vault(0) or M.workspaces[1]
    if not ws or not ws.path then
      return
    end
    local note_path = vim.fs.joinpath(ws.path, name)
    if not vim.endswith(note_path, ".md") then
      note_path = note_path .. ".md"
    end
    vim.cmd.edit(note_path)
    vim.bo.ft = "markdown"
    -- only seed frontmatter into a fresh note, never an existing one
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if #lines == 1 and lines[1] == "" then
      M.insert_frontmatter()
    end
  end)
end

---Open current buffer in obsidian
function M.open_in_obsidian()
  local current_path = vim.api.nvim_buf_get_name(0)
  local ws = M.get_vault(0)

  local obsidian_path = "obsidian://open"
  if ws then
    local vault_path = vim.fn.expand(ws.path)
    local vault_arg = vim.uri_encode(ws.name)
    local relative_path = current_path:sub(#vault_path + 1)
    local file_arg = vim.uri_encode(relative_path)
    obsidian_path = "obsidian://open?vault=" .. vault_arg .. "&file=" .. file_arg
  end

  vim.notify("opening " .. obsidian_path)

  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", obsidian_path }
  else -- Linux
    cmd = { "xdg-open", obsidian_path }
  end
  vim.system(cmd, { stdout = false, stderr = false })
end

--- Return the workspace that contains the given buffer's file, or nil.
---@param buf? integer buffer id, defaults to current buffer
---@return { name: string, path: string }|nil
function M.get_vault(buf)
  local path = vim.api.nvim_buf_get_name(buf or 0)
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
---@param buf? integer buffer id, defaults to current buffer
function M.insert_frontmatter(buf)
  buf = buf or 0
  local title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
  local lines = M.get_frontmatter { title = title }
  if not lines then
    return
  end
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, lines)
end

return M
