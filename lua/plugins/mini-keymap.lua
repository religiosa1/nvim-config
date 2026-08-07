return {
  {
    "nvim-mini/mini.keymap",
    config = function()
      local keymap = require("mini.keymap")
      keymap.map_multistep("i", "<A-Tab>", { "jump_after_close", "jump_after_tsnode" })
      keymap.map_multistep("i", "<A-S-Tab>", { "jump_before_open", "jump_before_tsnode" })
    end,
  },
}
