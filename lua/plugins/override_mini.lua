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
      -- for markdown fenced Code block, linewise
      -- "i" is content lines only (no fences, no ```lang), "a" includes fences
      opts.custom_textobjects.O = function(ai_type)
        local parser = vim.treesitter.get_parser(0, nil, { error = false })
        if not parser or parser:lang() ~= "markdown" then
          return {}
        end
        local root = parser:parse()[1]:root()
        local query = vim.treesitter.query.parse("markdown", "(fenced_code_block) @block")
        local regions = {}
        for _, block in query:iter_captures(root, 0) do
          local open_row = block:range()
          local close_row, content_end_row
          for child in block:iter_children() do
            if child:type() == "fenced_code_block_delimiter" and child:range() ~= open_row then
              close_row = child:range()
            elseif child:type() == "code_fence_content" then
              local _, _, end_row, end_col = child:range()
              -- content range usually ends at col 0 of the next line
              content_end_row = end_col == 0 and end_row - 1 or end_row
            end
          end
          local from_row, to_row
          if ai_type == "a" then
            from_row, to_row = open_row, close_row or content_end_row or open_row
          elseif content_end_row then
            from_row, to_row = open_row + 1, close_row and close_row - 1 or content_end_row
          end
          if from_row and to_row >= from_row then
            local last_line = vim.fn.getline(to_row + 1)
            table.insert(regions, {
              from = { line = from_row + 1, col = 1 },
              to = { line = to_row + 1, col = math.max(#last_line, 1) },
              vis_mode = "V",
            })
          end
        end
        return regions
      end
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
          { "aO", desc = "markdown code block with fences" },
          { "iO", desc = "markdown code block contents" },
        },
      })
    end,
  },
}
