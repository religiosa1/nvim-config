return {
  name = "colorcolumn-toggle",
  dir = vim.fn.stdpath("config"),
  lazy = true,
  config = function()
    -- Store the last non-empty colorcolumn value
    local last_cc = vim.o.cc or "80,120,140"

    -- Track changes to colorcolumn from any source
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "colorcolumn",
      callback = function()
        local current = vim.v.option_new
        if current ~= "" then
          last_cc = current
        end
      end,
    })

    vim.api.nvim_create_user_command("ColorcolumnToggle", function()
      if vim.o.cc == "" then
        vim.opt.cc = last_cc
      else
        vim.opt.cc = ""
      end
    end, {})
  end,
  keys = {
    {
      "<leader>uR",
      "<cmd>ColorcolumnToggle<CR>",
      desc = "Toggle ruler guides",
      mode = { "n" },
    },
  },
}
