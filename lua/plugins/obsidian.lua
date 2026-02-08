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
    {
      "<leader>Oo",
      "<cmd>Obsidian quick_switch<CR>",
      desc = "Quick switch to note",
      mode = { "n" },
    },
    -- Obsidian new creates notes with Zettelkasten style id -- which is also the buffer name.
    -- I don't like that, so we're just using the normal name from the input.
    {
      "<leader>On",
      function()
        Snacks.input.input({
          prompt = "Enter note name (optional)",
          completion = "file",
        }, function(value)
          local name = vim.trim(value)
          local has_name = name:len() > 0
          local id = has_name and name or nil
          local obsidian = require("obsidian")
          local note = obsidian.Note.create({
            id = id,
            -- TODO: figure out where this should come from
            -- template = Obsidian.opts.note.template,
          })
          -- Open the note in a new buffer.
          note:open({ sync = true })
          note:write_to_buffer({
            template = Obsidian.opts.note.template,
          })
          if has_name then
            vim.cmd("file " .. value .. ".md")
          end
        end)
      end,
      desc = "Create a new named note",
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
