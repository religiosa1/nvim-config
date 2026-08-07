return {
  {
    "nvim-mini/mini.keymap",
    config = function()
      local keymap = require("mini.keymap")
      -- escape hatch: force a pair/tsnode jump while a snippet session is
      -- holding on to <Tab>
      keymap.map_multistep("i", "<A-Tab>", { "jump_after_close", "jump_after_tsnode" })
      keymap.map_multistep("i", "<A-S-Tab>", { "jump_before_open", "jump_before_tsnode" })

      -- single owner for <Tab>; blink gives the key up in blink-cmp.lua.
      -- snippet jumps come before menu selection, otherwise the menu re-opening
      -- inside a tabstop swallows the jump. select mode is needed because
      -- vim.snippet selects placeholder text.
      --
      -- If we really need to insert a raw tab somewhere, we always
      -- have <C-v><Tab> escape hatch
      keymap.map_multistep({ "i", "s" }, "<Tab>", {
        "vimsnippet_next",
        "blink_next",
        "jump_after_close",
        "jump_after_tsnode",
        "increase_indent",
      })
      keymap.map_multistep({ "i", "s" }, "<S-Tab>", {
        "vimsnippet_prev",
        "blink_prev",
        "jump_before_open",
        "jump_before_tsnode",
        "decrease_indent",
      })
    end,
  },
}
