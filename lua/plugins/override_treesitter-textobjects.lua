-- free ]C / [C for native multicursor jumps
if vim.fn.has("nvim-0.13") == 0 then
  return {}
end

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  opts = function(_, opts)
    local keys = vim.tbl_get(opts, "move", "keys") or {}
    if keys.goto_next_end then
      keys.goto_next_end["]C"] = nil
    end
    if keys.goto_previous_end then
      keys.goto_previous_end["[C"] = nil
    end
  end,
}
