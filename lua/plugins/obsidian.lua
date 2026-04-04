-- FIXME: Obsidian plugin does a lot of unnecessary shit.
-- We'd be better of just inlining a couple of commands.
--
-- Basically, we just need an option to search for notes + create a new one with
-- the default template, which we can probably interpolate with the new Obsidian CLI.

local workspaces = {
  {
    name = "personal",
    path = "~/Documents/obsidian",
  },
}
--- Get current or the first workspace path
--- @return string | nil
local function get_workspace_path()
  local ws_path
  if Obsidian and Obsidian.workspace then
    ws_path = tostring(Obsidian.workspace.path)
  else
    ws_path = workspaces[1].path
  end
  if not ws_path then
    return nil
  end
  return vim.fn.expand(ws_path)
end

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
      local ws_path = get_workspace_path()
      local full_path = ws_path and vim.fs.joinpath(ws_path, name .. ".md") or name .. ".md"
      vim.cmd("file " .. full_path)
    end
  end)
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  ft = "markdown",
  init = function()
    require("which-key").add({
      { "<leader>O", group = "Obsidian", icon = { cat = "extension", name = "md" } },
    })
  end,
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false, -- this will be removed in the next major release
    workspaces = workspaces,
    attachments = {
      folder = "attachments",
    },
    note = {
      -- this is IIFE, but obsidian-nvim doesn't support lazy evaluation here
      template = (function()
        local template_name = "templates/frontmatter.md"
        local ws_path = get_workspace_path()
        local template_path = ws_path and vim.fs.joinpath(ws_path, template_name) or template_name
        if vim.uv.fs_stat(template_path) == nil then
          return nil
        else
          return template_path
        end
      end)(),
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
        Snacks.picker.files({
          cwd = get_workspace_path(),
        })
      end,
      desc = "Open a note",
      mode = { "n" },
    },
    {
      "<leader>Oc",
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
