local langmap = require("util.langmap")

local cyrillicLabels = "фывапролдйцукенгшщзячсмить"
local allCyrillicLabels = cyrillicLabels .. vim.fn.toupper(cyrillicLabels)

-- raw key that triggered the last mapping, before 'langmap'
local last_typed

return {
  "folke/flash.nvim",
  init = function()
    -- 0.13 applies 'langmap' before mapping lookup, so "ы" lands on the "s"
    -- mapping; on_key's typed arg is the only way to tell the layouts apart
    vim.on_key(function(_, typed)
      if typed ~= "" then
        last_typed = typed
      end
    end, vim.api.nvim_create_namespace("flash_trigger_layout"))
  end,
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
        local cyrillic = last_typed == langmap.get("s")
        require("flash").jump(cyrillic and { labels = allCyrillicLabels } or nil)
      end,
      desc = "Flash",
    },
    -- TODO: remove after 0.13 release
    -- cyrillic flash for 0.12, where 'langmap' doesn't apply to multibyte lhs
    {
      langmap.get("s"),
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
