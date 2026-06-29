local cyrillicLabels = "фывапролдйцукенгшщзячсмить"
local allCyrillicLabels = cyrillicLabels .. vim.fn.toupper(cyrillicLabels)

return {
  "folke/flash.nvim",
  opts = {
    modes = {
      -- turbo treesitter select: keep labels (jump to any scope), and reuse
      -- flash's own ;/, expand/shrink closures so re-pressing the trigger grows
      -- the selection and <bs> shrinks it -- frees <C-space> for layout switching.
      treesitter = {
        actions = {
          ["S"] = "next", -- expand to parent node (swap with "prev" if reversed)
          ["<bs>"] = "prev", -- shrink to child node
        },
      },
      char = {
        -- for now just disabling the backdrop for flash for movements f F t T
        -- keeping it for multi-line search mostly
        highlight = { backdrop = false },
        -- If we want to keep it partially a couple of extra options down below:
        autohide = true,
        -- enabled = false,
      },
    },
  },
  keys = {
    -- disable the default flash keymap
    { "s", mode = { "n", "x", "o" }, false },
    -- enabling it only for normal mode, so it doesn't conflict with ys from mini.surround
    {
      "s",
      mode = { "n" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
    -- cyrillic flash
    {
      "ы",
      mode = { "n" },
      function()
        require("flash").jump { labels = allCyrillicLabels }
      end,
      desc = "Flash",
    },
    -- disable "nvim-treesitter incremental selection", as it conflicts with my layout switching
    -- keybinding + superseded by the turbo treestitter select above
    { "<C-Space>", mode = { "n", "o", "x" }, false },
  },
}
