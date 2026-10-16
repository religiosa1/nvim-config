local tmux_commands = {
  left = "TmuxNavigateLeft",
  down = "TmuxNavigateDown",
  up = "TmuxNavigateUp",
  right = "TmuxNavigateRight",
}

local wincmd_keys = { left = "h", down = "j", up = "k", right = "l" }

-- vim-tmux-navigator counterpart for herdr: at the edge of nvim's windows, focus the
-- neighbor herdr pane. Ctrl-hjkl reach nvim through herdr's navigate.sh binding.
local function herdr_navigate(direction)
  local win = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(wincmd_keys[direction])
  if vim.api.nvim_get_current_win() ~= win then
    return
  end
  vim.system({ "herdr", "pane", "layout", "--current" }, { text = true }, function(layout)
    local ok, response = pcall(vim.json.decode, layout.stdout)
    -- Same as tmux_navigator_disable_when_zoomed
    if layout.code ~= 0 or not ok or response.result.layout.zoomed then
      return
    end
    vim.system({ "herdr", "pane", "focus", "--current", "--direction", direction })
  end)
end

local function navigate(direction)
  return function()
    -- Inside tmux running in a herdr pane, tmux is the closer multiplexer
    if vim.env.TMUX == nil and vim.env.HERDR_ENV == "1" then
      herdr_navigate(direction)
    else
      vim.cmd(tmux_commands[direction])
    end
  end
end

return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  init = function()
    vim.g.tmux_navigator_disable_when_zoomed = 1
    -- Otherwise the plugin's own mappings replace the ones below once it loads
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<c-h>", navigate("left") },
    { "<c-j>", navigate("down") },
    { "<c-k>", navigate("up") },
    { "<c-l>", navigate("right") },
    -- Outside tmux this is plain `wincmd p`, so it works under herdr as is
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
  },
}
