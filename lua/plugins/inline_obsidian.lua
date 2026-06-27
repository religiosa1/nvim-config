local Obsidian = require("util.obsidian")

-- Shared snacks picker opts: search the first vault by default, with <a-w>
-- toggling to search across every configured vault.
local function vault_scope_opts()
  return {
    dirs = { Obsidian.workspaces[1].path },
    toggles = { all_vaults = "w" },
    actions = {
      toggle_vaults = function(picker)
        picker.opts.all_vaults = not picker.opts.all_vaults
        picker.opts.dirs = picker.opts.all_vaults and Obsidian.vault_paths() or { Obsidian.workspaces[1].path }
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
      function()
        Snacks.picker.files(vim.tbl_deep_extend("force", vault_scope_opts(), {
          live = true, -- setting live for case-insensitive non-latin search
        }))
      end,
      desc = "Find obsidian note",
    },
    {
      "<leader>Ns",
      function()
        Snacks.picker.grep(vault_scope_opts())
      end,
      desc = "Grep obsidian notes",
    },
    {
      "<leader>Nn",
      function()
        Snacks.input.input({
          prompt = "Enter note name",
          completion = "file",
        }, function(value)
          local name = value and vim.trim(value) or ""
          if name == "" then
            return
          end
          -- create relative to the current vault if we're in one, else the first
          local ws = Obsidian.get_vault(0) or Obsidian.workspaces[1]
          if not ws or not ws.path then
            return
          end
          local note_path = vim.fs.joinpath(ws.path, name)
          if not vim.endswith(note_path, ".md") then
            note_path = note_path .. ".md"
          end
          vim.cmd.edit(note_path)
          vim.bo.ft = "markdown"
          -- only seed frontmatter into a fresh note, never an existing one
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          if #lines == 1 and lines[1] == "" then
            Obsidian.insert_frontmatter()
          end
        end)
      end,
      desc = "New obsidian note",
    },
    {
      "<leader>NO",
      function()
        local current_path = vim.api.nvim_buf_get_name(0)
        local ws = Obsidian.get_vault(0)

        local obsidian_path = "obsidian://open"
        if ws then
          local vault_path = vim.fn.expand(ws.path)
          local vault_arg = vim.uri_encode(ws.name)
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
      end,
      desc = "Open in Obsidian",
    },
  },
}
