-- TODO: technically, an array, but the code itself only supports single item for now
local workspaces = {
  {
    name = "obsidian",
    path = "~/Documents/obsidian/"
  },
}

return {
  name = "obsidian-search-create",
  dir = vim.fn.stdpath("config"),
  lazy = true,
  init = function()
    require("which-key").add({
      { "<leader>N", group = "Obsidian notes", icon = { icon = "", color = "orange" } },
    })
  end,
  keys = {
    {
      "<leader>No",
      function()
        Snacks.picker.files({
          cwd = workspaces[1].path,
          live = true, -- setting live for case-insensitive non-latin search
        })
      end,
      desc = "Find obsidian note"
    },
    {
      "<leader>Ns",
      function()
        Snacks.picker.grep({
          cwd = workspaces[1].path,
        })
      end,
      desc = "Grep obsidian notes"
    },
    {
      "<leader>Nn",
      function()
        Snacks.input.input({
          prompt = "Enter note name",
          completion = "file",
        }, function(value)
          if #workspaces == 0 or not workspaces[1].path then
            return
          end
          local name = vim.trim(value)
          local ws_path = workspaces[1].path
          local note_path = vim.fs.joinpath(ws_path, name)
          if not vim.endswith(note_path, ".md") then
            note_path = note_path .. ".md"
          end
          vim.cmd.edit(note_path)
        end)
      end,
      desc = "New obsidian note"
    },
    {
      "<leader>NO",
      function()
        local current_path = vim.api.nvim_buf_get_name(0)
        local vault_path = vim.fn.expand(workspaces[1].path)
        local vault_name = workspaces[1].name

        local is_buf_in_vault = vim.startswith(current_path, vault_path)

        local obsidian_path = "obsidian://open"
        if is_buf_in_vault then
          local vault_arg = vim.uri_encode(vault_name)
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
      desc = "Open in Obsidian"
    },
  }
}
