-- Folding plugin
-- https://www.ericapisani.dev/how-to-install-nvim-ufo-in-lazyvim-to-enable-foldable-code-blocks/
return {
  "kevinhwang91/nvim-ufo",
  dependencies = {
    { "kevinhwang91/promise-async" },
  },
  opts = function(_, opts)
    vim.o.foldcolumn = "1" -- '0' is not bad
    -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    -- Using ufo provider need remap `zR` and `zM`.
    vim.keymap.set("n", "zR", require("ufo").openAllFolds)
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

    return vim.tbl_deep_extend("force", opts, {
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
    })
  end,
}
