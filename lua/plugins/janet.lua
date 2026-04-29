vim.filetype.add({
  extension = { janet = "janet", jdn = "janet" },
})
vim.keymap.set("v", "<localleader>c", function()
  local region = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  local input = table.concat(region, "\n")
  local output = vim.fn.system("janet -q", input)
  vim.notify(output)
end, { desc = "Run Janet Selection" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "janet",
  callback = function(ev)
    vim.keymap.set("n", "<localleader>r", function()
      local file = vim.api.nvim_buf_get_name(ev.buf)
      vim.system({ "janet", file }, { text = true }, function(result)
        local output = (result.stdout or "") .. (result.stderr or "")
        local lines = vim.split(output, "\n", { trimempty = false })
        vim.schedule(function()
          vim.cmd("botright split")
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_win_set_buf(0, buf)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        end)
      end)
    end, { buffer = ev.buf, desc = "Run current file with janet" })

    vim.keymap.set("n", "<localleader>c", function()
      local output = vim.fn.system("janet -q", ev.buf)
      vim.notify(output)
    end, { buffer = ev.buf, desc = "Run Janet Snippet" })
  end,
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    ft = "janet",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "janet_simple" })
    end,
  },
}
