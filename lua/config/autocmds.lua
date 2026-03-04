-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disabling builtin-in spellchecker in favor of codebook for:
-- "text", "plaintex", "typst", "gitcommit", "markdown
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Enabling wrapping back though
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- command for cleaning up CLI drawboxes in markdown: tables drawn by claude or duckdb
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.api.nvim_buf_create_user_command(ev.buf, "CleanBoxChars", function(opts)
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
    end, { range = true, desc = "Replace box-drawing characters" })

    vim.keymap.set("x", "<leader>cb", ":<C-u>'<,'>CleanBoxChars<CR>", { buffer = ev.buf, desc = "Clean box chars" })
  end,
})
