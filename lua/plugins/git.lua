--- jump to the diff window, execute a cmd and jump back
--- @param cmd string command to execute
local function diffViewCmd(cmd)
  return function()
    vim.cmd("wincmd l")
    vim.cmd(cmd)
    vim.cmd("wincmd h")
  end
end

return {
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      -- Only one of these is needed.
      "dlyongemallo/diffview-plus.nvim",
      -- "sindrets/diffview.nvim",        -- optional
      -- "esmuellert/codediff.nvim",      -- optional

      -- For a custom log pager
      "m00qek/baleia.nvim", -- optional

      -- Only one of these is needed.
      "folke/snacks.nvim",
    },
    init = function()
      local group = vim.api.nvim_create_augroup("NeogitTabline", { clear = true })

      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function()
          if vim.bo.filetype == "NeogitStatus" then
            vim.o.showtabline = 0
          end
        end,
      })

      vim.api.nvim_create_autocmd("BufLeave", {
        group = group,
        callback = function()
          if vim.bo.filetype == "NeogitStatus" and vim.g._saved_showtabline ~= nil then
            vim.o.showtabline = 1
          end
        end,
      })
    end,
    opts = {
      mappings = {
        commit_editor = {
          ["<esc><esc>"] = "Close",
        },
        rebase_editor = {
          ["<esc><esc>"] = "Close",
        },
        status = {
          ["<esc><esc>"] = "Close",
        },
      },
    },
    cmd = "Neogit",
    keys = {
      -- use kind replace if tabs are getting tiresome
      { "<leader>gg", "<cmd>Neogit kind=tab<cr>", desc = "Show Neogit UI" },
    },
  },
  {
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    lazy = true,
    cmd = {
      "DiffviewOpen",
      "DiffviewToggle",
      "DiffviewFileHistory",
      "DiffviewDiffFiles",
      "DiffviewLog",
    },
    opts = {
      show_help_hints = false,
      -- adding ]h to the existing ]c for consistency
      keymaps = {
        view = {
          { "n", "<esc><esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "]h", "]c", { desc = "Next diff hunk" } },
          { "n", "[h", "[c", { desc = "Prev diff hunk" } },
        },
        file_panel = {
          { "n", "<esc><esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          { "n", "]h", "]c", { desc = "Next diff hunk" } },
          { "n", "[h", "[c", { desc = "Prev diff hunk" } },
          -- fold/unfold without switching focus to diff view
          { "n", "zr", diffViewCmd("normal! zr"), { desc = "Open all folds in diff" } },
          { "n", "zR", diffViewCmd("normal! zR"), { desc = "Open all level folds in diff" } },
          { "n", "zm", diffViewCmd("normal! zm"), { desc = "Close all folds in diff" } },
          { "n", "zM", diffViewCmd("normal! zM"), { desc = "Close all level folds in diff" } },
        },
        file_history_panel = {
          { "n", "<esc><esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        },
      },
      hooks = {
        view_enter = function()
          vim.o.showtabline = 0
        end,
        view_leave = function()
          vim.o.showtabline = 1
        end,
      },
    },
    keys = {
      {
        "<leader>gd",
        function()
          vim.cmd("DiffviewToggle")
          -- If we want to not show tabs we can do something like this instead.
          -- if next(require("diffview.lib").views) == nil then
          --   vim.cmd("DiffviewOpen")
          -- else
          --   vim.cmd("DiffviewClose")
          -- end
        end,
        desc = "Toggle Diffview",
      },
      {
        "<leader>gD",
        function()
          -- Try main first, fall back to master
          local result = vim.fn.systemlist { "git", "rev-parse", "--verify", "main" }
          local ok = vim.v.shell_error == 0 and result[1] ~= nil and result[1] ~= ""
          local branch = ok and "main" or "master"
          vim.cmd("DiffviewOpen " .. branch)
        end,
        desc = "Diff against main/master",
      },
      {
        "<leader>gb",
        "<cmd>.DiffviewFileHistory --follow<CR>",
        mode = { "n" },
        desc = "Blame line",
      },
      {
        "<leader>gb",
        "<Esc><cmd>'<,'>DiffviewFileHistory --follow<CR>",
        mode = { "x" },
        desc = "Blame Selection",
      },
      {
        "<leader>gf",
        "<cmd>DiffviewFileHistory %<cr>",
        desc = "File history",
      },
      {
        "<leader>gF",
        "<cmd>DiffviewFileHistory<cr>",
        desc = "File History (repo)",
      },
    },
  },
}
