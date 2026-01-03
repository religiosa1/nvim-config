-- "Outline" picker, de-cluttered version of <leader>ss
-- lsp_symbols for typescript contains too much noise and at the same time
-- doesn't contain enough -- for example, no top level functional expressions
-- assigned to variables. So we're gathering the outline of a TS file with a
-- tree-sitter query.

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

---Find parent container (function, class) skipping the current symbol
---@param name_node TSNode
---@return TSNode?
local function find_parent_container(name_node)
  -- First, find the current symbol container
  local current_container = find_symbol_container(name_node)
  if not current_container then
    return nil
  end

  -- For methods, check if they're inside a class
  if current_container:type() == "method_definition" then
    -- Walk up to find class_body, then class_declaration
    local parent = current_container:parent()
    while parent do
      if parent:type() == "class_body" then
        -- Get the class_declaration parent
        return parent:parent()
      end
      parent = parent:parent()
    end
  end

  -- For other symbols, find parent function/class
  local current = current_container:parent()
  while current do
    local type = current:type()
    if
      type == "function_declaration"
      or type == "arrow_function"
      or type == "function_expression"
      or type == "class_declaration"
    then
      return current
    end
    current = current:parent()
  end
  return nil
end

-- Tree-sitter query to capture functions, classes, and methods
local query_string = [[
(function_declaration
  name: (identifier) @function.name)

(lexical_declaration
  (variable_declarator
    name: (identifier) @arrow.name
    value: [(arrow_function) (function_expression)]))

(class_declaration
  name: (type_identifier) @class.name)

(method_definition
  name: [(property_identifier) (private_property_identifier)] @method.name)
]]

---@class OutlineNode
---@field name string
---@field kind string
---@field pos snacks.picker.Pos
---@field fn_node TSNode
---@field parent_fn TSNode

---get all "interesting" for outline nodes
---@param parser vim.treesitter.LanguageTree
---@param buffer_id number
---@return OutlineNode[]
local function get_outline_nodes(parser, buffer_id)
  local tree = parser:parse()[1]
  local root = tree:root()
  local query = vim.treesitter.query.parse("typescript", query_string)

  local function_nodes = {}
  for id, node, _ in query:iter_captures(root, buffer_id) do
    local capture_name = query.captures[id]

    if
      capture_name ~= "function.name"
      and capture_name ~= "arrow.name"
      and capture_name ~= "class.name"
      and capture_name ~= "method.name"
    then
      goto iter_captures
    end

    local symbol_container = find_symbol_container(node)
    if not symbol_container then
      goto iter_captures
    end

    local kind = "Function" -- default

    local name = vim.treesitter.get_node_text(node, buffer_id)

    -- Determine kind based on capture type
    if capture_name == "function.name" then
      kind = "Function"
    elseif capture_name == "arrow.name" then
      -- Walk up to find lexical_declaration and check keyword
      local declarator = node:parent()
      local declaration = declarator and declarator:parent()
      if declaration and declaration:type() == "lexical_declaration" then
        local keyword_node = declaration:child(0)
        if keyword_node then
          local keyword = vim.treesitter.get_node_text(keyword_node, buffer_id)
          kind = (keyword == "const") and "Constant" or "Variable"
        end
      end
    elseif capture_name == "class.name" then
      kind = "Class"
    elseif capture_name == "method.name" then
      -- Check if this is a constructor
      if name == "constructor" then
        kind = "Constructor"
      else
        -- Check if this is a getter or setter
        local accessor_type = nil
        for child in symbol_container:iter_children() do
          local child_text = vim.treesitter.get_node_text(child, buffer_id)
          if child_text == "get" or child_text == "set" then
            accessor_type = child_text
            break
          end
        end

        if accessor_type then
          kind = "Property"
          -- Add (get) or (set) prefix to the name
          name = "(" .. accessor_type .. ") " .. name
        else
          kind = "Method"
        end
      end
    end
    local start_row, start_col = node:start()
    local parent_container = find_parent_container(node)

    table.insert(function_nodes, {
      name = name,
      kind = kind,
      pos = { start_row + 1, start_col },
      fn_node = symbol_container,
      parent_fn = parent_container,
    })
    ::iter_captures::
  end
  return function_nodes
end

---Build a hierarchical tree of items, based on the found outline nodes.
---@param outline_nodes OutlineNode
---@param file_path string
---@return snacks.picker.Item[]
local function build_tree(outline_nodes, file_path)
  local items = {}
  local last_child_tracker = {}

  -- Create a virtual root for the file (like LSP symbols does)
  local file_root = { text = "", root = true }

  local function add_item(fn_data, parent_item)
    local item = {
      text = fn_data.name,
      name = fn_data.name,
      kind = fn_data.kind,
      file = file_path,
      pos = fn_data.pos,
      tree = true,
      parent = parent_item,
    }

    items[#items + 1] = item

    -- Track as potential last child
    if parent_item then
      last_child_tracker[parent_item] = item
    end

    -- Add children recursively
    for _, child_fn in ipairs(outline_nodes) do
      if child_fn.parent_fn == fn_data.fn_node then
        add_item(child_fn, item)
      end
    end
  end

  -- Start with root-level symbols, all parented to file_root
  for _, fn_data in ipairs(outline_nodes) do
    if not fn_data.parent_fn then
      add_item(fn_data, file_root)
    end
  end

  -- Mark last children
  for _, last_child in pairs(last_child_tracker) do
    last_child.last = true
  end

  return items
end

---Get snacks items for outline nodes for a typescript buffer with a treesitter
---query
---@return snacks.picker.Item[]
return function()
  local buffer_id = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(buffer_id, "typescript")
  assert(parser)

  local outline_nodes = get_outline_nodes(parser, buffer_id)
  local file_path = vim.api.nvim_buf_get_name(buffer_id)
  return build_tree(outline_nodes, file_path)
end
