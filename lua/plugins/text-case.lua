return {
  "johmsalas/text-case.nvim",
  enabled = true,
  -- text case will load only after lsp is attached
  lazy = true,
  event = "VeryLazy",
  config = true,
  cmd = {
    "Subs",
    "TextCaseStartReplacingCommand",
  },
  keys = {
    "ga",
  },
}
