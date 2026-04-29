require("which-key").add({
  { "<leader>9", group = "99 AI", icon = { icon = "🌠", color = "yellow" }, mode = { "n", "v" } },
})

return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")

    _99.setup({
      provider = _99.Providers.ClaudeCodeProvider, -- default: OpenCodeProvider
      model = "haiku",

      -- When setting this to something that is not inside the CWD tools
      -- such as claude code or opencode will have permission issues
      -- and generation will fail refer to tool documentation to resolve
      -- https://opencode.ai/docs/permissions/#external-directories
      -- https://code.claude.com/docs/en/permissions#read-and-edit
      tmp_dir = "./tmp",

      --- Completions: #rules and @files in the prompt buffer
      completion = {
        --- A list of folders where you have your own SKILL.md
        --- Expected format:
        --- /path/to/dir/<skill_name>/SKILL.md
        ---
        --- Example:
        --- Input Path:
        --- "scratch/custom_rules/"
        ---
        --- Output Rules:
        --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
        --- ... the other rules in that dir ...
        ---
        custom_rules = {
          "scratch/custom_rules/",
        },
      },
    })

    vim.keymap.set("v", "<leader>9", function()
      _99.visual({})
    end, { desc = "Visual prompt" })

    vim.keymap.set("n", "<leader>9x", function()
      _99.stop_all_requests()
    end, { desc = "Stop all requests" })

    vim.keymap.set("n", "<leader>9s", function()
      _99.search({})
    end, { desc = "Search" })

    vim.keymap.set("n", "<leader>9v", function()
      _99.search({})
    end, { desc = "Vibe" })

    vim.keymap.set("n", "<leader>9h", function()
      _99.open()
    end, { desc = "History" })

    -- vim.keymap.set("n", "<leader>9t", function()
    --   _99.tutorial({})
    -- end, { desc = "Tutorial" })
  end,
}
