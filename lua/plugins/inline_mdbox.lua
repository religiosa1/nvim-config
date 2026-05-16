-- command for cleaning up CLI drawboxes in markdown: tables drawn by claude or duckdb
return {
  name = "clean-box-chars",
  dir = vim.fn.stdpath("config"),
  lazy = true,
  -- ft = "markdown",
  config = function()
    vim.api.nvim_create_user_command("CleanBoxChars", function(opts)
      -- Delete table top and bottom borders first
      vim.cmd(opts.line1 .. "," .. opts.line2 .. [[ g/\s*[┌└][─┬┴]*[┐┘]/d _]])
      -- Re-clamp range since deletions may have shifted/shrunk it
      local last = vim.fn.line("$")
      local l1 = math.min(opts.line1, last)
      local l2 = math.min(opts.line2, last)

      if l1 > l2 then
        return
      end
      local range = l1 .. "," .. l2
      vim.cmd(range .. [[ s/[├┼┤│]/|/g ]])
      vim.cmd(range .. [[ s/─/-/g ]])

      local search_pattern = [[^\s*|\(-*|\)\+\s*$]]
      -- move cursor to the start of the range, so search will work
      vim.fn.cursor(l1, 1)
      local first_match = vim.fn.search(search_pattern, "n", l2)

      if first_match > 0 and first_match < l2 then
        range = (first_match + 1) .. "," .. l2
        vim.cmd(range .. "g/" .. search_pattern .. "/d _")
      end
    end, { range = true, desc = "L" })
  end,
  keys = {
    {
      "<leader>jt",
      ":<C-u>'<,'>CleanBoxChars<CR>",
      desc = "Clean out box-drawing characters",
      mode = { "x" },
    },
  },
}
