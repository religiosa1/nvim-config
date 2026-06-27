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
    local items = vim
      .iter(paths)
      :map(function(path)
        local safe = path:gsub([[\]], [[\\]]):gsub([["]], [[\"]])
        return string.format([[POSIX file "%s"]], safe)
      end)
      :totable()
    local list = "{" .. table.concat(items, ", ") .. "}"
    result = vim.fn.system {
      "osascript",
      "-e",
      [[tell application "Finder" to set the clipboard to ]] .. list,
    }
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

---Yank a path into the system register and notify, applying a modifier first.
---@param path string absolute path
---@param modifier string fnamemodify modifier, e.g. ":." for relative, ":p" for absolute
---@param title string notification title
local function yank_path(path, modifier, title)
  local result = vim.fn.fnamemodify(path, modifier)
  vim.fn.setreg("+", result)
  vim.notify(result, vim.log.levels.INFO, { title = title, ft = "text" })
end

---Yank a file's path relative to the cwd into the system register.
---@param path string absolute path
M.yank_relative_path = function(path)
  yank_path(path, ":.", "Relative path copied to register")
end

---Yank a file's absolute path into the system register.
---@param path string absolute path
M.yank_absolute_path = function(path)
  yank_path(path, ":p", "Absolute path copied to register")
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
