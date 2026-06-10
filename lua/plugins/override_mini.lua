return {
  {
    "nvim-mini/mini.pairs",
    config = function(_, opts)
      LazyVim.mini.pairs(opts)

      local pairs = require("mini.pairs")
      local open = pairs.open
      -- overriding open to account for unbalanced quotes
      pairs.open = function(pair, neigh_pattern)
        local o, c = pair:sub(1, 1), pair:sub(2, 2)
        if o == c then
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before = line:sub(1, col):gsub("\\.", "") -- drop escaped chars
          local _, count = before:gsub(vim.pesc(o), "")
          if count % 2 == 1 then
            return o -- odd quote already open on line -> just close, don't pair
          end
        end
        return open(pair, neigh_pattern)
      end
    end,
  },
  {
    "nvim-mini/mini.surround",
    opts = function(_, opts)
      opts.custom_surroundings = opts.custom_surroundings or {}
      -- "j" for generic: identifier (word/./:: chars) followed by balanced <>
      -- e.g. Array<string>, Map<K, V>, Vec::<i32>
      opts.custom_surroundings.j = {
        input = { "%f[%w_%.:][%w_%.:]+%b<>", "^.-<().*()>$" },
        output = function()
          local name = MiniSurround.user_input("Generic name")
          if name == nil then
            return nil
          end
          return { left = name .. "<", right = ">" }
        end,
      }
    end,
  },
  {
    "nvim-mini/mini.ai",
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      -- "m" for method-chain link, incl. the leading '.' or ':' -- and potentially trailing . for go
      -- %s between . and the word is for capturing trailing . syntax, as in golang
      opts.custom_textobjects.m = {
        "[.:]%s*[%w_]+%b()", -- around
        "^[.:]%s*[%w_]+%(().*()%)$", -- inner
      }
      -- "j" for generic: identifier (word/./:: chars) followed by balanced <>
      -- e.g. Array<string>, Map<K, V>, Vec::<i32>
      -- "a" is just "<...>" (name kept), "i" is content inside <>
      opts.custom_textobjects.j = {
        "%f[%w_%.:][%w_%.:]+%b<>",
        "^.-()<().-()>()$",
      }
    end,
  },
  -- which-key helper to go with it
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.spec, {
        {
          mode = { "x", "o" }, -- visual + operator-pending, same as mini.ai's objects
          { "am", desc = "method chain link" },
          { "im", desc = "method chain args" },
          { "aj", desc = "generic <...> with name" },
          { "ij", desc = "generic <...> contents" },
        },
      })
    end,
  },
}
