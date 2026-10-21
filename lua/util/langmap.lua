local M = {}

-- cache of latin -> langmapped char lookup, rebuilt when 'langmap' changes
local cache = { source = nil, lookup = {} }

--- Build latin -> langmapped lookup from 'langmap' option.
---
--- Only pair form is supported ("ЙQ,йq"), commas between pairs are optional
--- (same as in nvim itself), backslash escapes the next char.
---@param langmap string
---@return table<string, string>
local function parse_langmap(langmap)
  local chars = {}
  local escaped = false
  for _, char in ipairs(vim.fn.split(langmap, "\\zs")) do
    if escaped then
      table.insert(chars, char)
      escaped = false
    elseif char == "\\" then
      escaped = true
    elseif char == ";" then
      error("langmap: 'abc;xyz' form is not supported")
    elseif char ~= "," then
      table.insert(chars, char)
    end
  end
  -- NOTE: escaped commas get here as regular chars, so plain char pairing is fine
  local lookup = {}
  for i = 1, #chars - 1, 2 do
    local from, to = chars[i], chars[i + 1]
    lookup[to] = lookup[to] or from
  end
  return lookup
end

---@return table<string, string>
local function get_lookup()
  local langmap = vim.o.langmap
  if cache.source ~= langmap then
    cache = { source = langmap, lookup = parse_langmap(langmap) }
  end
  return cache.lookup
end

--- Split lhs into keys: one key notation (`<C-w>`, `<Leader>`) or one char per key.
---@param lhs string
---@return string[]
local function split_keys(lhs)
  local keys = {}
  local i = 1
  while i <= #lhs do
    local key
    if lhs:sub(i, i) == "<" then
      local close = lhs:find(">", i + 1, true)
      local candidate = close and lhs:sub(i, close)
      -- lone "<" or "<foo>" isn't a key notation and is kept as a regular char
      if candidate and vim.keycode(candidate) ~= candidate then
        key = candidate
      end
    end
    key = key or lhs:match("^[%z\1-\127\194-\244][\128-\191]*", i)
    table.insert(keys, key)
    i = i + #key
  end
  return keys
end

--- Remap a single key, including the char in modifier notation (`<C-w>` -> `<C-ц>`).
---@param key string
---@param lookup table<string, string>
---@return string
local function remap_key(key, lookup)
  if lookup[key] then
    return lookup[key]
  end
  if not key:match("^<.+>$") then
    return key
  end
  local mods, name = "", key:sub(2, -2)
  while true do
    local mod, rest = name:match("^(%a%-)(.+)$")
    if not mod then
      break
    end
    mods, name = mods .. mod, rest
  end
  local mapped = lookup[name]
  if mods == "" or not mapped then
    return key
  end
  -- nvim folds shift into the char only for ascii, so non-ascii uppercase with
  -- modifiers arrives as e.g. <M-S-Р> instead of <M-Р>
  if vim.fn.tolower(mapped) ~= mapped and not mods:upper():find("S-", 1, true) then
    mods = mods .. "S-"
  end
  return "<" .. mods .. mapped .. ">"
end

--- Get mapped keybinding for a lhs mapping expression.
---
--- @usage vim.keymap.set("n", langmap.get("<Leader><C-z>"), "<cmd>FooCmd<cr>")
--- -- set a duplicate for existing binding for the langmapped version as well
---
--- @param lhs string left-hand-side expression in latin/english
--- @return string lhs-expression for the langmap version (which can be the same
--- as the originally provided lhs expression)
function M.get(lhs)
  local lookup = get_lookup()
  local keys = split_keys(lhs)
  for i, key in ipairs(keys) do
    keys[i] = remap_key(key, lookup)
  end
  return table.concat(keys)
end

--- Set a keybinding, duplicating LHS for langmapped version as well.
---
--- Duplicates call signature of `vim.keymap.set()` to be used as drop-in
--- replacement, where you need to set a kybinding for both english latin and
--- langmapped version
---
---@param modes string|string[] mode or modes to set the command in
---@param lhs string left-hand-side expression in english, will be remapped to langmap as well
---@param rhs string | function right-hand-side expression or a func
---@param opts vim.keymap.set.Opts? extra options
function M.set_keymap(modes, lhs, rhs, opts)
  vim.keymap.set(modes, lhs, rhs, opts)

  local remapped_lhs = M.get(lhs)
  if remapped_lhs ~= lhs then
    vim.keymap.set(modes, remapped_lhs, rhs, opts)
  end
end

return M
