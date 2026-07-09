---parses input string into two ints for table creation
---@param input string
---@return integer,integer
local function tokenize_input(input)
  local values = {}
  for token in input:gmatch("[^%sa-zA-Z,\"'`%[%]{}()=:;]+") do
    local num = tonumber(token)
    if num ~= nil then
      table.insert(values, num)
    end
    if #values == 2 then
      break
    end
  end
  return values[1], values[2]
end

--- generate a markdown table row of repeated string of a given size
--- @param value string value to repeat
--- @param size integer number of columns
--- @return string
local function markdown_table_row_of(value, size)
  local header_delimiter = "| "
  for i = 1, size do
    header_delimiter = header_delimiter .. value
    if i ~= size then
      header_delimiter = header_delimiter .. " | "
    end
  end
  header_delimiter = header_delimiter .. " |"
  return header_delimiter
end

---creates a markdown table of the specified size
---@param x integer
---@param y integer
---@return string[]
local function create_table_lines(x, y)
  x = x or 1
  local make_header_cont = function(v)
    return string.format("Header %d", v)
  end

  if x <= 0 then
    return {}
  end

  local lines = {}
  -- header first
  local headers = {}
  for i = 1, x do
    table.insert(headers, make_header_cont(i))
  end
  table.insert(lines, "| " .. table.concat(headers, " | ") .. " |")

  local header_cont_size = #headers[1]
  local delim_cont = string.rep("-", header_cont_size)
  table.insert(lines, markdown_table_row_of(delim_cont, x))

  if not y or y < 0 then
    return lines
  end

  -- the main lines now
  local row_cont = string.rep(" ", header_cont_size)
  for _ = 1, y do
    table.insert(lines, markdown_table_row_of(row_cont, x))
  end
  return lines
end

vim.api.nvim_create_autocmd("FileType", {
  desc = "enabling table-drawing keymaps",
  pattern = { "text", "plaintext", "typst", "markdown" },
  callback = function(args)
    local buf_id = args.buf
    vim.keymap.set({ "n" }, "<leader>jt", function()
      local input_str = vim.fn.input {
        prompt = "Enter table size",
      }
      if not input_str then
        return
      end
      local x, y = tokenize_input(input_str)
      local lines = create_table_lines(x, y)
      vim.api.nvim_put(lines, "l", true, false)
    end, {
      buf = buf_id,
      desc = "Draw a markdown table",
    })
  end,
})
