-- Show the current Claude Code conversation next to its <C-g> prompt buffer.
local M = {}

--- Whether the buffer is a Claude Code <C-g> prompt file ($TMPDIR/claude-prompt-*.md).
---@param buf integer
function M.is_prompt_buffer(buf)
  return vim.fs.basename(vim.api.nvim_buf_get_name(buf)):match("^claude%-prompt.*%.md$") ~= nil
end

--- Transcript of the session that spawned this nvim.
---@return string?
local function transcript_path()
  local projects = vim.fs.normalize("~/.claude/projects")
  local session_id = vim.env.CLAUDE_CODE_SESSION_ID
  if session_id then
    local found = vim.fn.glob(projects .. "/*/" .. session_id .. ".jsonl", false, true)[1]
    if found then
      return found
    end
  end
  -- ponytail: newest transcript of cwd's project; wrong if two sessions run in the same dir.
  local slug = vim.fn.getcwd():gsub("[^%w]", "-")
  local files = vim.fn.glob(projects .. "/" .. slug .. "/*.jsonl", false, true)
  table.sort(files, function(a, b)
    return vim.uv.fs_stat(a).mtime.sec > vim.uv.fs_stat(b).mtime.sec
  end)
  return files[1]
end

---@param content string|table
---@return string
local function text_of(content)
  if type(content) == "string" then
    return content
  end
  local parts = {}
  for _, block in ipairs(content) do
    if block.type == "text" then
      table.insert(parts, block.text)
    end
  end
  return table.concat(parts, "\n")
end

--- Conversation messages as { role, text }, tool calls and subagents skipped.
---@param path string
---@return { role: string, text: string }[]
function M.read_messages(path)
  local messages = {}
  for line in io.lines(path) do
    local ok, entry = pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
    if ok and (entry.type == "user" or entry.type == "assistant") and not entry.isSidechain and entry.message then
      local text = text_of(entry.message.content or "")
      if text ~= "" then
        local last = messages[#messages]
        -- one assistant turn is spread over several records (text, tool_use, text...)
        if last and last.role == entry.message.role then
          last.text = last.text .. "\n\n" .. text
        else
          table.insert(messages, { role = entry.message.role, text = text })
        end
      end
    end
  end
  return messages
end

---@param lines string[]
local function show(lines)
  vim.cmd("aboveleft new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
  vim.cmd("normal! G")
end

--- Open the conversation in a split.
---@param last_only boolean only the last assistant message
function M.open(last_only)
  local path = transcript_path()
  if not path then
    vim.notify("Claude transcript not found", vim.log.levels.WARN)
    return
  end
  local messages = M.read_messages(path)
  if last_only then
    for i = #messages, 1, -1 do
      if messages[i].role == "assistant" then
        return show(vim.split(messages[i].text, "\n"))
      end
    end
    return show({})
  end
  local lines = {}
  for _, message in ipairs(messages) do
    vim.list_extend(lines, { "## " .. message.role, "" })
    vim.list_extend(lines, vim.split(message.text, "\n"))
    table.insert(lines, "")
  end
  show(lines)
end

--- Buffer-local keymaps for a prompt buffer.
---@param buf integer
function M.attach(buf)
  local langmap = require("util.langmap")
  langmap.set_keymap("n", "<leader>ii", function()
    M.open(true)
  end, { buffer = buf, desc = "Claude: last message" })
  langmap.set_keymap("n", "<leader>iI", function()
    M.open(false)
  end, { buffer = buf, desc = "Claude: full conversation" })
end

return M
