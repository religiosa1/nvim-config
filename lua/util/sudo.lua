local M = {}

---Run a command under sudo, prompting for a password only if credentials aren't cached.
---Neovim's :! has no tty, so sudo can't prompt by itself.
---@param cmd string[]
---@return vim.SystemCompleted?
local function run_sudo(cmd)
  if vim.system({ "sudo", "-n", "true" }):wait().code == 0 then
    return vim.system(vim.list_extend({ "sudo", "-n" }, cmd)):wait()
  end
  local password = vim.fn.inputsecret("[sudo] password: ")
  if password == "" then
    return nil
  end
  return vim.system(vim.list_extend({ "sudo", "-S", "-p", "" }, cmd), { stdin = password .. "\n" }):wait()
end

---Write the current buffer to its file with sudo.
M.write = function()
  local path = vim.fn.expand("%:p")
  if path == "" or vim.bo.buftype ~= "" then
    vim.notify("Current buffer is not a file", vim.log.levels.WARN)
    return
  end
  local tmp = vim.fn.tempname()
  vim.cmd { cmd = "write", args = { tmp }, bang = true, mods = { silent = true, keepalt = true } }
  -- cp onto an existing file keeps its owner and mode
  local result = run_sudo { "cp", tmp, path }
  vim.fn.delete(tmp)
  if not result then
    return
  end
  if result.code ~= 0 then
    vim.notify("Sudo write failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
    return
  end
  vim.bo.modified = false
  -- sync buffer with the new mtime, so the next :w doesn't warn about an external change
  vim.cmd.checktime(vim.api.nvim_get_current_buf())
  vim.notify("Written with sudo: " .. path, vim.log.levels.INFO)
end

return M
