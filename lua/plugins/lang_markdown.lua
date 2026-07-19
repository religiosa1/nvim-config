return {
  -- don't forget to install lang.markdown from lazy-extras for render-markdown.nvim and toc
  -- also prettier for formatter
  -- Overriding conceallevel settings for render-markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        -- Let snacks own mermaid blocks: render-markdown's code-block decoration
        -- (conceal + padding) breaks snacks' inline image placement, leaving
        -- mermaid stuck in float-only and ignoring the <leader>uM inline/float
        -- toggle. Disabling render here lets snacks render + switch it like math.
        disable = { "mermaid" },
        conceal_delimiters = false,
        border = "none", -- to show backticks, otherwise we can always use "thick"
      },
      win_options = {
        -- https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/e41b0002fe4196825450ab5a6343300c40791d51/README.md?plain=1#L639-L644
        -- See :h 'conceallevel'
        conceallevel = {
          -- Defaults to getting conceallevel from opts, but its' set in autocmd, so overriding manually to 0
          default = 0, -- default is vim.api.nvim_get_option_value('conceallevel', {})
          -- Used when being rendered, concealed text is completely hidden
          rendered = 3,
        },
      },
    },
  },
  -- `latex` parser drives both math highlight and snacks image rendering of
  -- $$...$$ / $...$ (```math ... ``` would still work though). But also give a nive
  -- syntax highlight
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "latex" } } },
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
            desc = "enabling codelens for markdow_oxide backreference count",
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
  {
    "religiosa1/markdown-table.nvim",
    -- dev = true,
    -- dir = "~/Projects/markdown-table.nvim",
    lazy = true,
    ft = { "markdown", "text", "plaintext" },
    init = function()
      require("which-key").add {
        { "<leader>jt", group = "Markdown table" },
      }
    end,
    keys = {
      {
        "<leader>jtt",
        function()
          require("markdown-table").create_table()
        end,
        mode = { "n" },
        desc = "Create a markdown table",
      },
      {
        "<leader>jtd",
        function()
          require("markdown-table").delete_column { to_reg = true }
        end,
        mode = { "n", "x" },
        desc = "Delete a markdown table column",
      },
      {
        "<leader>jtD",
        function()
          require("markdown-table").delete_column()
        end,
        mode = { "n", "x" },
        desc = "Delete a markdown table column into a black hole",
      },
      {
        "<leader>jtA",
        function()
          require("markdown-table").paste_column { paste_mode = "before" }
        end,
        mode = { "n" },
        desc = "Add a markdown table column before",
      },
      {
        "<leader>jta",
        function()
          require("markdown-table").paste_column { paste_mode = "after" }
        end,
        "<Plug>(MarkdownTableAddColumnAfter)",
        mode = { "n" },
        desc = "Add a markdown table column after",
      },
      {
        "<leader>jtP",
        function()
          require("markdown-table").paste_column { paste_mode = "before", from_reg = true }
        end,
        mode = { "n" },
        desc = "Paste a markdown table column before",
      },
      {
        "<leader>jtp",
        function()
          require("markdown-table").paste_column { paste_mode = "after", from_reg = true }
        end,
        mode = { "n" },
        desc = "Paste a markdown table column after",
      },
    },
  },
}
