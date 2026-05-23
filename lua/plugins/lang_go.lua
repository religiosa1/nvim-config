-- see also
-- https://github.com/neovim/nvim-lspconfig/issues/888#issuecomment-834515521

-- Fix Mason Go tool installation: mise shim overrides GOBIN, bypassing Mason's
-- staging dir. Prepend real Go bin so Mason spawns the real binary directly.
-- This definitely works in options.lua, let's see if it works here as well.
if vim.fn.executable("mise") == 1 then
  local go_bin = vim.fn.system("mise which go 2>/dev/null"):gsub("\n", "")
  if go_bin ~= "" then
    local go_bin_dir = vim.fn.fnamemodify(go_bin, ":h")
    vim.env.PATH = go_bin_dir .. ":" .. vim.env.PATH
  end
end

-- Maybe move gotags thing on lsp attach instead

vim.api.nvim_create_user_command("GoTags", function(opts)
  local tags_prefix = "-tags="
  local clients = vim.lsp.get_clients { name = "gopls" }
  if #clients == 0 then
    vim.notify("no gopls LSP client found to apply buildtags", vim.log.levels.ERROR)
  end
  if opts.args == "" then
    --- @type string[]
    local tags_by_client = {}
    for _, client in ipairs(clients) do
      local flags = vim.tbl_get(client, "settings", "gopls", "buildFlags")
      if flags ~= nil then
        --- @type string?
        local tag_flag = vim.iter(flags):find(function(flag)
          return vim.startswith(flag, tags_prefix)
        end)
        if tag_flag ~= nil then
          table.insert(tags_by_client, tag_flag:sub(#tags_prefix + 1))
        end
      end
    end
    vim.notify("gopls tags: " .. (#tags_by_client > 0 and table.concat(tags_by_client, "\n") or "(none)"))
  else
    local tags = opts.args ~= "-" and opts.args or ""
    for _, client in ipairs(clients) do
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        gopls = {
          buildFlags = tags ~= "" and { tags_prefix .. tags } or {},
        },
      })
      ---@diagnostic disable-next-line: param-type-mismatch seems to work just fine
      client.notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
    vim.notify("set gopls tags: " .. (tags == "" and "(none)" or tags))
  end
end, { nargs = "?", desc = "Get or set go build tags (use `-` arg to clear)" })

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = {
                ST1000 = false, -- annoying "each package must have docs"
              },
            },
          },
        },
      },
    },
  },
}
