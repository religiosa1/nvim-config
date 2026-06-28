local Obsidian = require("util.obsidian")

return {
  name = "obsidian-search-create",
  dir = vim.fn.stdpath("config"),
  lazy = true,
  init = function()
    require("which-key").add {
      { "<leader>N", group = "Obsidian notes", icon = { icon = "", color = "orange" } },
    }
    -- <leader>Nf is only meaningful inside a vault, so bind it buffer-locally
    -- when we enter a buffer that lives in one (keeps it out of the global map).
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("obsidian_inline", { clear = true }),
      pattern = "*.md",
      callback = function(args)
        if not Obsidian.get_vault(args.buf) then
          return
        end
        vim.keymap.set("n", "<leader>Nf", function()
          Obsidian.insert_frontmatter(0)
        end, { buffer = args.buf, desc = "Insert frontmatter template" })
      end,
    })
  end,
  keys = {
    {
      "<leader>No",
      Obsidian.find_note,
      desc = "Find obsidian note",
    },
    {
      "<leader>Ns",
      Obsidian.grep_note,
      desc = "Grep obsidian notes",
    },
    {
      "<leader>Nn",
      Obsidian.new_note_in_dir,
      desc = "New obsidian note (pick folder)",
    },
    {
      "<leader>NN",
      Obsidian.new_note,
      desc = "New obsidian note (type path)",
    },
    {
      "<leader>NO",
      -- Maybe this also only makes sense inside of a vault, but technically
      -- can work anywhere, so we're not gating it.
      Obsidian.open_in_obsidian,
      desc = "Open in Obsidian",
    },
  },
}
