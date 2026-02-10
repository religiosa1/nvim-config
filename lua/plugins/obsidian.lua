-- Obsidian new creates notes with Zettelkasten style id -- which is also the buffer name.
-- I don't like that, so we're just using the normal name from the input.
local function create_new_note()
  Snacks.input.input({
    prompt = "Enter note name (optional)",
    completion = "file",
  }, function(value)
    local name = vim.trim(value)
    local has_name = name:len() > 0
    local obsidian = require("obsidian")
    -- Note creation part is a direct copy of what's used inside of the `new` command
    local id = has_name and name or nil
    local note = obsidian.Note.create({
      id = id,
      template = Obsidian.opts.note.template,
    })
    note:open({ sync = true })
    note:write_to_buffer({
      template = Obsidian.opts.note.template,
    })
    -- Renaming the buffer afterwords, for the same title inside of a workspace
    if has_name then
      local ws_path
      if Obsidian.workspace then
        ws_path = tostring(Obsidian.workspace.path)
      elseif Obsidian.opts.workspaces[1].path then
        ws_path = tostring(Obsidian.opts.workspaces[1].path)
      end
      local full_path = ws_path and vim.fn.expand(ws_path) .. "/" .. name .. ".md" or name .. ".md"
      vim.cmd("file " .. full_path)
    end
  end)
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  ft = "markdown",
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false, -- this will be removed in the next major release
    workspaces = {
      {
        name = "personal",
        path = "~/Documents/obsidian",
      },
    },
    attachments = {
      folder = "attachments",
    },
  },
  keys = {
    {
      "<leader>OO",
      "<cmd>Obsidian<CR>",
      desc = "Obsidian command picker",
      mode = { "n" },
    },
    -- TODO: automatically write it, which I hate.
    {
      "<leader>Od",
      "<cmd>Obsidian today<cr>",
      desc = "Obsidian daily note",
      mode = { "n" },
    },
    {
      "<leader>Oo",
      -- ditching obsidian's quick_switch thing, as it doesn't allow to open in a split
      function()
        local ws_path = Obsidian.workspace and tostring(Obsidian.workspace.path)
          or vim.fn.expand(tostring(Obsidian.opts.workspaces[1].path))
        Snacks.picker.files({
          cwd = ws_path,
        })
      end,
      desc = "Open a note",
      mode = { "n" },
    },
    {
      "<leader>On",
      create_new_note,
      desc = "Create a new note",
      mode = { "n" },
    },
    {
      -- Obsidian.nvim provides toc command, but the output looks miserably:
      -- it grabs the relative path to the file, which generates too much noise
      -- and make it basically unreadable. We're just grabbing lsp_symbols filtered
      "<leader>Ot",
      function()
        Snacks.picker.lsp_symbols({
          title = "Table of Contents",
          filter = {
            -- seems to be good, but keep an eye here
            markdown = { "String" },
          },
        })
      end,
      desc = "TOC",
      mode = { "n" },
    },
  },
}
