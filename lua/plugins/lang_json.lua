return {
  {
    "phelipetls/jsonpath.nvim",
    ft = { "json", "jsonc" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable copy json-path keymaps",
        pattern = { "json", "jsonc" },
        callback = function()
          vim.keymap.set("n", "<leader>jp", function()
            local jp = require("jsonpath").get()
            vim.fn.setreg("+", jp)
            vim.notify(jp, vim.log.levels.INFO, { title = "Copied JSON path" })
          end, { buffer = true, desc = "Copy JSON path" })
        end,
      })
    end,
  },
}
