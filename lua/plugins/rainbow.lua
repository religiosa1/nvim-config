return {
  "HiPhish/rainbow-delimiters.nvim",
  lazy = false,
  keys = {
    {
      "<leader>uP",
      function()
        local rd = require("rainbow-delimiters")
        local buf = vim.api.nvim_get_current_buf()
        rd.toggle(buf)
        local state = rd.is_enabled(buf) and "enabled" or "disabled"
        Snacks.notify.info("Rainbow delimiters " .. state, { title = "Toggle" })
      end,
      desc = "Toggle Rainbow Delimiters",
    },
  },
}
