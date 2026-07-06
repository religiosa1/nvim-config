---@type "all" | "staged" | "unstaged"
local target = "all"

-- gitsigns with some of the keybindings overwritten + ability to go over staged hunks
return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  opts = {
    attach_to_untracked = true,
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
      end

      -- stylua: ignore start
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next", { target = target })
        end
      end, "Next Hunk")

      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev", { target = target })
        end
      end, "Prev Hunk")

     map("n", "<leader>ght", function()
        if target == "all" then
          target = "unstaged"
        else
          target = "all"
        end
        vim.notify(target, vim.log.levels.INFO, { title = "Git Hunks navigation" })
      end, "Toggle hunks nav type")

      map("n", "]H", function() gs.nav_hunk("last", { target = "all" }) end, "Last Hunk")
      map("n", "[H", function() gs.nav_hunk("first", { target = "all" }) end, "First Hunk")
      map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      -- default is ghS
      map("n", "<leader>gha", gs.stage_buffer, "Stage (git add) Buffer")
      map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>ghP", gs.preview_hunk, "Preview Hunk")
      map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
      map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
      map("n", "<leader>ghd", gs.diffthis, "Diff This")
      map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
    end,
  },
}
