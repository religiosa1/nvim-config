--- utils for obsidian vault detection and frontmatter templates
local M = {}

--- @class Vault vault configuration
--- @field name string name of the vault
--- @field path string path to the vault
--- @field inbox_note? string inbox note override for the vault
--- @field template_dir? string relative path to the template directory of the vault
--- @field default_template? string | false default template override (false to disable)

--- Configuration of vaults. At least one vault must be configured.
--- @type Vault[]
M.vaults = {
  {
    name = "obsidian",
    path = "~/Documents/obsidian/",
  },
}

--- Relative path inside of a vault for the inbox note
M.inbox_note = "!inbox.md"

--- Default template dir
M.template_dir = "templates"
--- Default template to use when creating a note, relative to the template dir
M.default_template = "frontmatter.md"

--- Folder names excluded from the new-note folder picker (in addition to any
--- hidden dotdir). These hold non-note content you'd never target a note into.
M.ignored_dirs = { "templates", "attachments" }

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

---@class RenderTemplateArgs
---@field lines string[] template lines
---@field ctx? { title?: string } extra substitution context

--- Render Obsidian-style template.
--- Supports {{date}}, {{time}}, {{title}} and the {{date:FORMAT}} /
--- {{time:FORMAT}} variants (FORMAT being moment.js tokens).
---@param args RenderTemplateArgs
---@return string[] rendered template lines
local function render_template(args)
  local ctx = args.ctx or {}
  return vim
    .iter(args.lines)
    :map(function(str)
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
    end)
    :totable()
end

-- Shared snacks picker opts: search the first vault by default, with <a-w>
-- toggling to search across every configured vault.
local function vault_scope_opts()
  return {
    dirs = { M.vaults[1].path },
    toggles = { all_vaults = "w" },
    actions = {
      toggle_vaults = function(picker)
        picker.opts.all_vaults = not picker.opts.all_vaults
        picker.opts.dirs = picker.opts.all_vaults and M.vault_paths() or { M.vaults[1].path }
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
function M.open_note()
  Snacks.picker.files(vim.tbl_deep_extend("force", vault_scope_opts(), {
    live = true, -- setting live for case-insensitive non-latin search
  }))
end

---Open a picker, that searches a note by text entry
function M.grep_note()
  Snacks.picker.grep(vault_scope_opts())
end

--- Create (and open) a note named `name` under `dir`. Adds the .md extension,
--- creates any missing parent dirs (:edit won't), and seeds frontmatter only
--- into a freshly created, empty note.
--- @param dir string vault path
--- @param name string note name
local function create_or_open_note(dir, name)
  name = name and vim.trim(name) or ""
  if name == "" then
    return
  end
  local note_path = vim.fs.joinpath(dir, name)
  if not vim.endswith(note_path, ".md") then
    note_path = note_path .. ".md"
  end
  vim.fn.mkdir(vim.fs.dirname(note_path), "p")
  vim.cmd.edit(note_path)
  vim.bo.ft = "markdown"

  local buf_id = 0 -- zero for current after edit
  local is_buf_empty = vim.api.nvim_buf_line_count(buf_id) == 1
    and vim.api.nvim_buf_get_lines(buf_id, 0, 1, false)[1] == ""
  if is_buf_empty then
    M.insert_template()
  end
end

--- Recursively collect note folders under `root`, pruning hidden dotdirs and
--- M.ignored_dirs (pruning skips their subtrees too).
--- @param root string root path to traverse
--- @return string[] list of dir paths
local function collect_dirs(root)
  local is_ok_dir = function(dir_name)
    local base = vim.fs.basename(dir_name)
    return base:sub(1, 1) ~= "." and not vim.tbl_contains(M.ignored_dirs, base)
  end
  local dirs = vim
    .iter(vim.fs.dir(root, {
      depth = 30,
      skip = is_ok_dir,
    }))
    :filter(function(name, type)
      return type == "directory" and is_ok_dir(name)
    end)
    :map(function(name)
      return vim.fs.joinpath(root, name)
    end)
    :totable()
  table.insert(dirs, 1, root)
  return dirs
end

--- Vault root that M.complete_note_dir completes against. Set by M.new_note
--- right before opening the input, since the completefunc (reached via v:lua)
--- gets no context of its own.
M._complete_root = nil

--- Tab-completion source for M.new_note: vault-relative directory paths only
--- (no files -- you pick the folder here, then type the note name).
--- Prunes the same dirs as the folder picker (hidden dotdirs and
--- M.ignored_dirs) by going through collect_dirs. Wired in as
--- a `customlist` completion string.
--- @param arg_lead string the partial path typed so far
--- @return string[] matching dir paths, each with a trailing slash
function M.complete_note_dir(arg_lead)
  local root = M._complete_root
  if not root then
    return {}
  end
  local out = {}
  for _, dir in ipairs(collect_dirs(root)) do
    local rel = dir:sub(#root + 1):gsub("^/", "")
    if rel ~= "" then
      rel = rel .. "/"
      if vim.startswith(rel, arg_lead) then
        out[#out + 1] = rel
      end
    end
  end
  return out
end

--- Create a new note, typing the path with vault-rooted directory completion.
--- Creates in the current vault, or the first vault if outside one.
function M.new_note()
  local buf_vault = M.get_vault()
  local vault = buf_vault or M.vaults[1]
  local root = vim.fn.expand(vault.path)
  -- Prefill with the current buffer's folder (relative to the vault root) so a
  -- new note lands next to the one being viewed. Empty at the vault root or
  -- when the buffer is outside a vault.
  local default = ""
  if buf_vault then
    local buf_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local rel = buf_dir:sub(#root + 1):gsub("^/", "")
    if rel ~= "" then
      default = rel .. "/"
    end
  end
  -- "arg" passed to the complete_note_dir
  M._complete_root = root
  Snacks.input.input({
    prompt = "Enter note name",
    default = default,
    -- Complete directories only (not files), rooted at the vault and pruned to
    completion = "customlist,v:lua.require'util.obsidian'.complete_note_dir",
  }, function(value)
    create_or_open_note(root, value)
  end)
end

--- Open the preconfigured inbox note
function M.open_inbox_note()
  local vault = M.get_vault() or M.vaults[1]
  local inbox_note = vault.inbox_note or M.inbox_note
  create_or_open_note(vim.fn.expand(vault.path), inbox_note)
end

--- Create a new note, fuzzy-selecting the target folder first.
function M.new_note_in_dir()
  local vault = M.get_vault() or M.vaults[1]
  local root = vim.fn.expand(vault.path)
  Snacks.picker.select(collect_dirs(root), {
    prompt = "Select folder",
    format_item = function(p)
      local rel = p:sub(#root + 1):gsub("^/", "")
      return rel == "" and "/" or rel
    end,
  }, function(dir)
    if not dir then
      return
    end
    Snacks.input.input({ prompt = "Enter note name" }, function(value)
      create_or_open_note(dir, value)
    end)
  end)
end

--- Open current buffer in obsidian
function M.open_in_obsidian()
  local current_path = vim.api.nvim_buf_get_name(0)
  local vault = M.get_vault(0)

  local obsidian_path = "obsidian://open"
  if vault then
    local vault_path = vim.fn.expand(vault.path)
    local vault_arg = vim.uri_encode(vault.name)
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

--- Return the vault that contains the given buffer's file, or nil.
--- @param buf? integer buffer id, defaults to current buffer
--- @return Vault?
function M.get_vault(buf)
  if #M.vaults == 0 then
    error("obsidian: no vault is configured")
  end
  local path = vim.api.nvim_buf_get_name(buf or 0)
  if path == "" then
    return nil
  end
  return vim.iter(M.vaults):find(function(vault)
    return vim.startswith(path, vim.fn.expand(vault.path))
  end)
end

--- Paths of every configured vault, for pickers that take a `dirs` list.
--- Left unexpanded -- snacks normalizes (and expands ~) on its own.
---@return string[]
function M.vault_paths()
  return vim
    .iter(M.vaults)
    :map(function(vault)
      return vault.path
    end)
    :totable()
end

---@class TemplateIdentifier
---@field vault? Vault selected vault, or default vault if not provided
---@field template_name? string template file name (relative to vault template_dir), default vault's template if undefined

--- Get template body as an array of strings
--- @param args? TemplateIdentifier
--- @return string[]?
local function get_template(args)
  args = args or {}
  local vault = args.vault or M.vaults[1]
  if not vault then
    error("obsidian: no vault is configured")
  end
  local template_dir = vault.template_dir or M.template_dir
  local template_name = args.template_name
  if template_name == nil then
    template_name = vault.default_template
  end
  if template_name == nil then
    template_name = M.default_template
  end
  if not template_name then -- false or nil
    return nil
  end
  local template_path = vim.fn.expand(vim.fs.joinpath(vault.path, template_dir, template_name))
  local ok, lines = pcall(vim.fn.readfile, template_path)
  if not ok then
    error("obsidian: cannot read template " .. template_path)
  end
  return lines
end

--- Insert the rendered template into the buffer.
--- @param template_name? string
--- @param after? boolean insert template after cursor
function M.insert_template(template_name, after)
  local buf = 0
  local vault = M.get_vault(buf) or M.vaults[1]
  local template_lines = get_template { vault = vault, template_name = template_name }
  local title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
  local lines = render_template { lines = template_lines or {}, ctx = { title = title } }
  if not lines then
    return
  end
  vim.api.nvim_put(lines, "l", after or false, true)
end

--- Open a picker for templates and insert the rendered selected template into the buffer.
--- @param after? boolean insert template after cursor
function M.pick_and_insert_template(after)
  local buf = 0
  local vault = M.get_vault(buf) or M.vaults[1]
  local template_dir = vault.template_dir or M.template_dir

  local templates_path = vim.fn.expand(vim.fs.joinpath(vault.path, template_dir))
  local templates = vim
    .iter(vim.fs.dir(templates_path))
    :filter(function(name, type)
      return type == "file" and vim.endswith(name, ".md")
    end)
    :map(function(name)
      return name
    end)
    :totable()

  Snacks.picker.select(templates, {
    prompt = "Select template",
  }, function(selection)
    if not selection then
      return
    end
    M.insert_template(selection, after)
  end)
end

return M
