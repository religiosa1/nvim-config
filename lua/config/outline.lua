-- "Outline" picker, de-cluttered version of <leader>ss
-- lsp_symbols for typescript contains too much noise and at the same time
-- doesn't contain enough -- for example, no top level functional expressions
-- assigned to variables. So we're gathering the outline of a TS file with a
-- tree-sitter query.

--- Tree-sitter query to capture functions, classes, and methods
local query_string = [[
(function_declaration
  name: (identifier) @function.name)

(lexical_declaration
  kind: "const"
  (variable_declarator
    name: (identifier) @arrow.name
    value: [(arrow_function) (function_expression)]))


((lexical_declaration
  kind: _ @kind
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)]))
  (#not-eq? @kind "const"))

(variable_declaration
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)]))

(class_declaration
  name: (type_identifier) @class.name)

(method_definition
  "get"
  name: (property_identifier) @getter.name)

(method_definition
  "set"
  name: (property_identifier) @setter.name)

(method_definition
  name: (property_identifier) @constructor
  (#eq? @constructor "constructor"))

(method_definition
  name: [(property_identifier) (private_property_identifier)] @method.name
  (#not-eq? @method.name "constructor"))
]]

---List of captures in treesitter query, that should result in a outline node
local relevant_captures = {
  "function.name",
  "arrow.name",
  "var_arrow.name",
  "class.name",
  "constructor",
  "method.name",
  "setter.name",
  "getter.name",
}

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

--- Extracting a name (symbol) for a tree sitter node.
--- For variable_declarator we're extracting from a variable name, for functions
--- classes and methods we're extracting it directly from the node.
--- Whatever the fuck that above means?
---@param name_node TSNode
---@return TSNode?
local function find_symbol_container(name_node)
  -- First check if this is a variable declarator with a function value
  -- Pattern: variable_declarator { name: identifier, value: arrow_function }
  local parent = name_node:parent()
  if parent and parent:type() == "variable_declarator" then
    -- Check if the value is a function
    for child in parent:iter_children() do
      local child_type = child:type()
      if child_type == "arrow_function" or child_type == "function_expression" then
        return child
      end
    end
  end

  -- Otherwise, walk up the tree to find a symbol container
  local current = name_node:parent()
  while current do
    local type = current:type()
    if
      type == "function_declaration"
      or type == "function_expression"
      or type == "arrow_function"
      or type == "class_declaration"
      or type == "method_definition"
    then
      return current
    end
    current = current:parent()
  end
  return nil
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
  elseif capture_name == "constructor" then
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

  for id, node, _ in query:iter_captures(root, buffer_id) do
    local capture_name = query.captures[id]

    if not vim.list_contains(relevant_captures, capture_name) then
      goto iter_captures
    end

    local symbol_container = find_symbol_container(node)
    if not symbol_container then
      goto iter_captures
    end

    local kind = get_node_kind(capture_name)
    local name = get_node_name(capture_name, vim.treesitter.get_node_text(node, buffer_id))
    local start_row, start_col, end_row, end_col = symbol_container:range()
    local pos = { start_row + 1, start_col }
    if positionsSet:add(pos) then
      table.insert(function_nodes, {
        name = name,
        kind = kind,
        pos = pos, -- 1-indexed for picker
        range = { start_row, start_col, end_row, end_col }, -- 0-indexed for comparison
      })
    end
    ::iter_captures::
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
  return build_tree(outline_nodes, file_path)
end
