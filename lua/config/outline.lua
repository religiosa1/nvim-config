-- "Outline" picker, de-cluttered version of <leader>ss
-- lsp_symbols for typescript contains too much noise and at the same time
-- doesn't contain enough -- for example, no top level functional expressions
-- assigned to variables. So we're gathering the outline of a TS file with a
-- tree-sitter query.

--- Tree-sitter query to capture functions, classes, and methods
local query_string = [[
(function_declaration
  name: (identifier) @function.name
) @function.definition

(lexical_declaration
  kind: "const"
  (variable_declarator
    name: (identifier) @arrow.name
    value: [(arrow_function) (function_expression)])
) @arrow.definition


((lexical_declaration
  kind: _ @kind
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)]))
  (#not-eq? @kind "const")
) @var_arrow.definition

(variable_declaration
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)])
) @var_arrow.definition

(class_declaration
  name: (type_identifier) @class.name
) @class.definition

(method_definition
  "get"
  name: (property_identifier) @getter.name
) @getter.definition

(method_definition
  "set"
  name: (property_identifier) @setter.name
) @setter.definition

(method_definition
  name: (property_identifier) @constructor.name
  (#eq? @constructor.name "constructor")
) @constructor.definition

(method_definition
  name: [(property_identifier) (private_property_identifier)] @method.name
  (#not-eq? @method.name "constructor")
) @method.definition
]]

---Set of outline positions in a file
---@class PositionSet
---@field private lines table<number, number[]> table of lines, containing array of columns
local PositionSet = {}
PositionSet.__index = PositionSet

---Create a new PositionSet instance
---@return PositionSet
function PositionSet.new()
  local self = setmetatable({}, PositionSet)
  self.lines = {}
  return self
end

---Add position to the set.
---@param pos snacks.picker.Pos
---@return true if pos was added to the set, false if it's already present
function PositionSet:add(pos)
  local line = pos[1]
  local col = pos[2]
  if not self.lines[line] then
    self.lines[line] = {}
  end

  local was_pos_in_set = vim.tbl_contains(self.lines[line], col)
  if not was_pos_in_set then
    table.insert(self.lines[line], col)
  end
  return not was_pos_in_set
end

--- Intermediate OutlineNode meta info
---@class OutlineNode
---@field name string
---@field kind string?
---@field pos snacks.picker.Pos -- 1-indexed: [line, col]
---@field range number[] -- 0-indexed: [start_line, start_col, end_line, end_col]

---Get the icon kind (for the icon) from the node
---@param capture_name string
---@return string?
local function get_node_kind(capture_name)
  if capture_name == "function.name" then
    return "Function"
  elseif capture_name == "arrow.name" then
    return "Constant"
  elseif capture_name == "var_arrow.name" then
    return "Variable"
  elseif capture_name == "class.name" then
    return "Class"
  elseif capture_name == "method.name" then
    return "Method"
  elseif capture_name == "constructor.name" then
    return "Constructor"
  elseif capture_name == "setter.name" or capture_name == "getter.name" then
    return "Property"
  end
end

---Get the icon kind (for the icon) from the node
---@param capture_name string
---@param node_text string
---@return string name to be displayed in the snacks picker
local function get_node_name(capture_name, node_text)
  if capture_name == "constructor" then
    return "constructor"
  end

  local name = node_text

  if capture_name == "getter.name" then
    name = "(get) " .. name
  elseif capture_name == "setter.name" then
    name = "(set) " .. name
  end
  return name
end

---Get a map of capture name to captured nodes that we got from a query
---@param query vim.treesitter.Query
---@param match table<integer, TSNode[]>
---@return table<string, TSNode>
local function get_captured_nodes(query, match)
  local captured_nodes = {}
  for id, node in pairs(match) do
    local capture_name = query.captures[id]
    -- If node is a table (array of nodes), take the first one
    local actual_node = type(node) == "table" and node[1] or node
    if capture_name then
      captured_nodes[capture_name] = actual_node
    end
  end
  return captured_nodes
end

---Determine "symbol type" from a map of captured_nodes -- symbol type being
---the part of capture name before the dot, e.g. "function", "var_arrow", etc.
---@param captured_nodes table<string, TSNode>
---@return string?
local function get_symbol_type(captured_nodes)
  ---@type string?
  local symbol_type = nil
  for capture_name in pairs(captured_nodes) do
    if capture_name:match("%.name$") then
      symbol_type = capture_name:match("^(.+)%.name$")
      break
    end
  end
  return symbol_type
end

---get all "interesting" for outline nodes
---@param parser vim.treesitter.LanguageTree
---@param buffer_id number
---@return OutlineNode[]
local function get_outline_nodes(parser, buffer_id)
  local tree = parser:parse()[1]
  local root = tree:root()
  local query = vim.treesitter.query.parse("typescript", query_string)

  local positionsSet = PositionSet.new()
  local function_nodes = {}

  for _, match in query:iter_matches(root, buffer_id) do
    local captured_nodes = get_captured_nodes(query, match)
    local symbol_type = get_symbol_type(captured_nodes)

    if not symbol_type then
      goto next_match
    end

    local name_node = captured_nodes[symbol_type .. ".name"]
    local def_node = captured_nodes[symbol_type .. ".definition"]

    if not (name_node and def_node) then
      goto next_match
    end

    local kind = get_node_kind(symbol_type .. ".name")
    local name = get_node_name(symbol_type .. ".name", vim.treesitter.get_node_text(name_node, buffer_id))
    local start_row, start_col, end_row, end_col = def_node:range()
    local pos = { start_row + 1, start_col }

    if positionsSet:add(pos) then
      table.insert(function_nodes, {
        name = name,
        kind = kind,
        pos = pos, -- 1-indexed for picker
        range = { start_row, start_col, end_row, end_col }, -- 0-indexed for comparison
      })
    end

    ::next_match::
  end
  return function_nodes
end

---Check if one node contains another (based on their position)
---@param parent OutlineNode
---@param child OutlineNode
---@return boolean
local function contains(parent, child)
  return parent.range[1] <= child.range[1] and parent.range[3] >= child.range[3]
end

---Build a hierarchical tree of items, based on the found outline nodes.
---@param outline_nodes OutlineNode
---@param file_path string
---@return snacks.picker.finder.Item[]
local function build_tree(outline_nodes, file_path)
  -- Sort by start position (line, then column)
  table.sort(outline_nodes, function(a, b)
    if a.range[1] ~= b.range[1] then
      return a.range[1] < b.range[1]
    end
    return a.range[2] < b.range[2]
  end)
  ---@type snacks.picker.finder.Item[]
  local items = {}
  local file_root = { text = "", root = true }
  -- Recursively build tree structure
  local function build_structure(nodes, parent_item, parent_range)
    while #nodes > 0 do
      local current = nodes[1]
      -- if current node is not contained in parent, return to previous level
      if parent_range and not contains(parent_range, current) then
        return
      end

      -- Remove from list and create item
      table.remove(nodes, 1)
      ---@type snacks.picker.finder.Item
      local item = {
        text = current.name,
        name = current.name,
        kind = current.kind,
        file = file_path,
        pos = current.pos,
        tree = true,
        parent = parent_item,
      }
      items[#items + 1] = item
      -- Recursively process children (nodes contained within current)
      build_structure(nodes, item, current)
      -- Mark as last child of parent if no more siblings
      if #nodes == 0 or (parent_range and not contains(parent_range, nodes[1])) then
        item.last = true
      end
    end
  end
  -- Build from root
  build_structure(outline_nodes, file_root, nil)
  return items
end

---Get snacks items for outline nodes for a typescript buffer with a treesitter
---query
---@return snacks.picker.finder.Item[]
return function()
  local buffer_id = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(buffer_id, "typescript")
  assert(parser)

  local outline_nodes = get_outline_nodes(parser, buffer_id)
  local file_path = vim.api.nvim_buf_get_name(buffer_id)
  local tree = build_tree(outline_nodes, file_path)
  return tree
end
