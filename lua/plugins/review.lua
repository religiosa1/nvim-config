-- Review notes: annotate diffview lines, export as markdown for a coding agent.
-- `add` works in diffview and plain file buffers; export/clear are global.
return {
  "religiosa1/review.nvim",
  opts = {},
  keys = {
    { "<leader>rr", function() require("review").add() end, desc = "add note on line" },
    { "<leader>ry", function() require("review").yank() end, desc = "yank review notes" },
    { "<leader>rw", function() require("review").export() end, desc = "export notes to a split (markdown)" },
    { "<leader>rx", function() require("review").clear() end, desc = "clear notes" },
    { "]r", function() require("review").jump(1) end, desc = "next review note" },
    { "[r", function() require("review").jump(-1) end, desc = "prev review note" },
    { 
      "<leader>rq", 
      function() 
        require("review").quickfix() 
        vim.cmd.copen() -- or vim.cmd("Trouble qflist")
      end,
      desc = "Review notes to quickfix",
    },
  },
}
