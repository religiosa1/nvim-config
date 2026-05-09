return {
  "johmsalas/text-case.nvim",
  enabled = true,
  -- problem with lazy here, it will only be launched after the first invocation, so first ga will be a miss
  lazy = false,
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
