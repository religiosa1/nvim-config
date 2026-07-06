--- jump to the diff window, execute a cmd and jump back
--- @param cmd string command to execute
local function diffViewCmd(cmd)
  return function()
    vim.cmd("wincmd l")
    vim.cmd(cmd)
    vim.cmd("wincmd h")
  end
end

--- Scroll the window under the *mouse pointer* (not the focused one), honoring
--- scrollbind so both diff panels stay in sync even when the wheel is used over
--- an unfocused window. Native mouse-wheel scrolls the window under the pointer
--- directly, which bypasses scrollbind; <C-e>/<C-y> via win_execute don't.
--- @param key string the scroll key, e.g. "<C-e>" or "<C-y>"
local function scrollMouseWin(key)
  local seq = "normal! 3" .. vim.keycode(key)
  return function()
    local winid = vim.fn.getmousepos().winid
    if winid ~= 0 then
      vim.fn.win_execute(winid, seq)
    end
  end
end

--- Global mouse-wheel maps that sync scrollbound windows. Installed only while a
--- diffview is entered (see hooks) so normal per-window mouse scroll is
--- unaffected elsewhere. Must be global, not buffer-local: a buffer-local map
--- only fires for the *focused* buffer, so it can't act on an unfocused window
--- the pointer happens to be over.
local wheelMaps = {
  ["<ScrollWheelDown>"] = scrollMouseWin("<C-e>"),
  ["<ScrollWheelUp>"] = scrollMouseWin("<C-y>"),
}
local function setWheelMaps()
  for lhs, rhs in pairs(wheelMaps) do
    vim.keymap.set({ "n", "x" }, lhs, rhs, { desc = "Diff-synced scroll under mouse" })
  end
end
local function delWheelMaps()
  for lhs in pairs(wheelMaps) do
    pcall(vim.keymap.del, { "n", "x" }, lhs)
  end
end

return {
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
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        { "n", "]h", "]c", { desc = "Next diff hunk" } },
        { "n", "[h", "[c", { desc = "Prev diff hunk" } },
        -- Synced mouse-wheel scroll is handled by global maps in the hooks
        -- below (needs to fire over unfocused windows, so can't be buffer-local).
      },
      file_panel = {
        { "n", "<esc><esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
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
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
    },
    hooks = {
      view_enter = function()
        vim.o.showtabline = 0
        setWheelMaps()
      end,
      view_leave = function()
        vim.o.showtabline = 1
        delWheelMaps()
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
      desc = "Diffview",
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
      "<leader>gl",
      "<cmd>DiffviewFileHistory<cr>",
      desc = "Git Log",
    },
  },
}
