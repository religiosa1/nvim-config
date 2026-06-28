return {
  -- don't forget to install lang.markdown from lazy-extras for render-markdown.nvim and toc
  -- aldo prettier for formatter
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Default linter is markdownlint-cli2, which sucks a bag of dicks,
        -- disabling it
        markdown = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then
                return true
              end
            end
          end,
        },
      },
    },
  },
  -- default iamcco/markdown-preview.nvim is basically abandonware at this point,
  -- it has an old mermaid version, which doesn't render half of things I need
  -- instead using this previewer which uses the same naming
  {
    "selimacerbas/markdown-preview.nvim",
    dependencies = { "selimacerbas/live-server.nvim" },
    lazy = true,
    keys = false, -- disabling any keybindings, need to call the command explicitly
  },
  -- Changing lsp for markdown from marskman to markdown_oxide
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.marksman = { enabled = false }
      -- markdown-oxide
      opts.servers.markdown_oxide = {
        -- Ensure that dynamicRegistration is enabled
        -- This allows the LS to take into account actions like Create Unresolved File, etc
        capabilities = vim.tbl_deep_extend(
          "force",
          vim.lsp.protocol.make_client_capabilities(),
          require("blink.cmp").get_lsp_capabilities(),
          {
            workspace = {
              didChangeWatchedFiles = {
                dynamicRegistration = true,
              },
            },
          }
        ),
        on_attach = function(client, bufnr)
          -- markdown_oxide's semantic tokens deadlock nvim: typing inside a
          -- partial link like `[x](` triggers a semanticTokens/full request that
          -- races the edit, server answers -32801 "Content modified", nvim
          -- re-requests, races again -> infinite loop on the main thread (editor
          -- hangs at 100% CPU). The tokens add nothing for a notes LSP, so drop
          -- the capability entirely.
          client.server_capabilities.semanticTokensProvider = nil
          -- normalize vim.NIL scheme values so mini.files doesn't crash on sync
          local file_ops = vim.tbl_get(client, "server_capabilities", "workspace", "fileOperations")
          if file_ops then
            for _, method_filters in pairs(file_ops) do
              if type(method_filters) == "table" and method_filters.filters then
                for _, fc in ipairs(method_filters.filters) do
                  if fc.scheme == vim.NIL then
                    fc.scheme = nil
                  end
                end
              end
            end
          end

          if client.name == "markdown_oxide" then
            -- natural language daily notes, e.g. `:Daily today`, `:Daily two days ago`, `:Daily -3`, etc.
            vim.api.nvim_create_user_command("Daily", function(args)
              local input = args.args
              client:exec_cmd { command = "jump", arguments = { input } }
            end, { desc = "Open daily note", nargs = "*" })
          end

          local function codelens_supported(bufnr)
            for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
              if c.server_capabilities and c.server_capabilities.codeLensProvider then
                return true
              end
            end
            return false
          end

          vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "CursorHold", "BufEnter" }, {
            buffer = bufnr,
            callback = function()
              if codelens_supported(bufnr) then
                vim.lsp.codelens.enable(true, { bufnr = bufnr })
              end
            end,
          })

          if codelens_supported(bufnr) then
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end
        end,
      } -- end opts.servers.markdown_oxide
    end, -- end opts func
  },
  -- command for cleaning up CLI drawboxes in markdown: tables drawn by claude or duckdb
  {
    name = "clean-box-chars",
    dir = vim.fn.stdpath("config"),
    lazy = true,
    -- ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
    config = function()
      vim.api.nvim_create_user_command("CleanBoxChars", function(opts)
        -- Delete table top and bottom borders first
        vim.cmd(opts.line1 .. "," .. opts.line2 .. [[ g/\s*[┌└][─┬┴]*[┐┘]/d _]])
        -- Re-clamp range since deletions may have shifted/shrunk it
        local last = vim.fn.line("$")
        local l1 = math.min(opts.line1, last)
        local l2 = math.min(opts.line2, last)

        if l1 > l2 then
          return
        end
        local range = l1 .. "," .. l2
        vim.cmd(range .. [[ s/[├┼┤│]/|/g ]])
        vim.cmd(range .. [[ s/─/-/g ]])

        local search_pattern = [[^\s*|\(-*|\)\+\s*$]]
        -- move cursor to the start of the range, so search will work
        vim.fn.cursor(l1, 1)
        local first_match = vim.fn.search(search_pattern, "n", l2)

        if first_match > 0 and first_match < l2 then
          range = (first_match + 1) .. "," .. l2
          vim.cmd(range .. "g/" .. search_pattern .. "/d _")
        end
      end, { range = true, desc = "Remove box-drawing chars" })
    end,
    keys = {
      {
        "<leader>jt",
        ":<C-u>'<,'>CleanBoxChars<CR>",
        desc = "Clean out box-drawing characters",
        mode = { "x" },
      },
    },
  },
}
