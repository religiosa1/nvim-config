--- utils for manipulating files in system clipboard
local M = {}

---Copies files to system clipboard.
---Only mac and wayland linux is supported. Wayland must have wl-clipboard utils installed (wl-copy)
---@param paths string[] absolute paths to files to copy
M.copy_files_to_clipboard = function(paths)
  if #paths == 0 then
    error("No files provided")
  end
  local result
  if vim.fn.has("mac") == 1 then
    local paths_json = vim.fn.json_encode(paths)
    local jxa = string.format(
      [[
        ObjC.import('AppKit');
        var paths = %s;
        var pb = $.NSPasteboard.generalPasteboard;
        pb.clearContents;
        var urls = $(paths.map(function(p) { return $.NSURL.fileURLWithPath(p); }));
        pb.writeObjects(urls);
      ]],
      paths_json
    )
    result = vim.fn.system { "osascript", "-l", "JavaScript", "-e", jxa }
  else -- Linux, wayland only
    local uris = vim
      .iter(paths)
      :map(function(path)
        return vim.uri_from_fname(path)
      end)
      :totable()
    result = vim.fn.system({ "wl-copy", "--type", "text/uri-list" }, table.concat(uris, "\r\n"))
  end
  if vim.v.shell_error ~= 0 then
    vim.notify("Copy failed: " .. result, vim.log.levels.ERROR)
  else
    local names = vim
      .iter(paths)
      :map(function(path)
        return vim.fn.fnamemodify(path, ":t")
      end)
      :totable()
    vim.notify(
      table.concat(names, "\n"),
      vim.log.levels.INFO,
      { title = "Copied file to system clipboard", ft = "text" }
    )
  end
end

---Yank text into the system register and notify.
---@param text string
---@param title string notification title
local function yank_text(text, title)
  vim.fn.setreg("+", text)
  vim.notify(text, vim.log.levels.INFO, { title = title, ft = "text" })
end

---Yank a path into the system register and notify, applying a modifier first.
---@param path string absolute path
---@param modifier string fnamemodify modifier, e.g. ":." for relative, ":p" for absolute
---@param title string notification title
local function yank_path(path, modifier, title)
  yank_text(vim.fn.fnamemodify(path, modifier), title)
end

---Get `target` path relative to `base` directory.
---Unlike vim.fs.relpath, walks up with ".." when `base` isn't an ancestor of `target`.
---@param base string absolute directory path
---@param target string absolute path
---@return string
local function relative_to(base, target)
  local base_parts = vim.split(vim.fs.normalize(base), "/", { trimempty = true })
  local target_parts = vim.split(vim.fs.normalize(target), "/", { trimempty = true })
  local common = 0
  while common < #base_parts and common < #target_parts and base_parts[common + 1] == target_parts[common + 1] do
    common = common + 1
  end
  local parts = {}
  for _ = common + 1, #base_parts do
    parts[#parts + 1] = ".."
  end
  vim.list_extend(parts, target_parts, common + 1)
  return #parts == 0 and "." or table.concat(parts, "/")
end

---Yank a file's path name into the system register
---@param path string absolute path
M.yank_file_name = function(path)
  yank_path(path, ":t", "Yanked file name")
end

---Yank a file's path relative to the cwd into the system register.
---@param path string absolute path
M.yank_relative_path = function(path)
  yank_path(path, ":.", "Yanked relative path")
end

---Yank a file's path relative to the base directory into the system register.
---@param path string absolute path
---@param base string absolute directory path
M.yank_path_relative_to = function(path, base)
  yank_text(relative_to(base, path), "Yanked path relative to buffer")
end

---Yank a file's absolute path into the system register.
---@param path string absolute path
M.yank_absolute_path = function(path)
  yank_path(path, ":p", "Yanked absolute path")
end

---Copy every file under the current visual selection to the system clipboard.
---Must be called while a visual selection is active.
---@param resolve fun(lnum: integer): string|nil maps a buffer line to an absolute path
M.copy_visual_selection_to_clipboard = function(resolve)
  local first = vim.fn.getpos("v")[2]
  local last = vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  local paths = {}
  for lnum = first, last do
    local path = resolve(lnum)
    if path then
      paths[#paths + 1] = path
    end
  end
  M.copy_files_to_clipboard(paths)
end

---Open file in the system app.
---Mac and Linux only
---@param path string absolute file path to open
M.open_file = function(path)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", path }
  else -- Linux
    cmd = { "xdg-open", path }
  end
  vim.system(cmd, { stdout = false, stderr = false })
end

return M
