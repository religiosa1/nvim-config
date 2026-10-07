-- :!cmd / :w !cmd output goes to an editable scratch split instead of noice's
-- read-only view (noice forces nomodifiable and re-renders over edits)
local output_text = ""
local output_buf ---@type integer?
local new_command = true

local function show_output()
  if not (output_buf and vim.api.nvim_buf_is_valid(output_buf)) then
    output_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[output_buf].bufhidden = "hide"
  end
  local lines = vim.split(output_text:gsub("\n$", ""), "\n")
  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines)

  if vim.fn.bufwinid(output_buf) == -1 then
    local win = vim.api.nvim_get_current_win()
    vim.cmd("botright " .. math.floor(vim.o.lines * 0.2) .. "split")
    vim.api.nvim_win_set_buf(0, output_buf)
    vim.api.nvim_set_current_win(win)
  end
end

return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.routes = opts.routes or {}
    table.insert(opts.routes, 1, {
      filter = { event = "msg_show", kind = { "shell_out", "shell_err" } },
      opts = { skip = true },
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
      pattern = ":",
      callback = function()
        if not vim.v.event.abort and vim.fn.getcmdline():find("!") then
          new_command = true
        end
      end,
    })

    local ui_opts = { ext_messages = true, ext_cmdline = true }
    vim.ui_attach(vim.api.nvim_create_namespace("shell_output"), ui_opts, function(event, kind, content, ...)
      -- output already lives in the split; skip nvim's post-shell getchar prompt
      if event == "cmdline_show" and select(2, ...) == "Press any key to continue" then
        vim.api.nvim_input("<Esc>")
        return
      end
      if event ~= "msg_show" or (kind ~= "shell_out" and kind ~= "shell_err") then
        return
      end
      if new_command then
        output_text, new_command = "", false
      end
      -- output may arrive in several chunks, split mid-line
      for _, chunk in ipairs(content) do
        output_text = output_text .. chunk[2]
      end
      vim.schedule(show_output)
    end)
  end,
}
