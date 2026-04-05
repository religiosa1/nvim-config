return {
  "nvim-mini/mini.files",
  lazy = false,
  opts = function(_, opts)
    opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
      -- default is "@"
      reveal_cwd = ";",
      -- default is "="
      synchronize = "<CR>",
    })
    -- Whether to use for editing directories.
    -- I disabled snacks.explorer, neovim is also diasbled, meaning we're actually
    -- falling back to netrw
    -- opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
    --   use_as_default_explorer = false,
    -- })
    return opts
  end,
  keys = {
    {
      "<leader>o",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (Directory of Current File)",
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local MiniFiles = require("mini.files")
        local buf_id = args.data.buf_id

        require("which-key").add({
          { "<leader>y", group = "Yank file path", buffer = buf_id },
        })

        local function copy_file_path(args)
          local curr_entry = MiniFiles.get_fs_entry()
          if curr_entry then
            local path
            if args and type(args.name) == "function" then
              path = args.name(curr_entry.path)
            else
              path = curr_entry.path
            end
            vim.fn.setreg("+", path)
            vim.notify(
              path,
              vim.log.levels.INFO,
              { title = (args and args.title) or "Absolute path copied to register", ft = "text" }
            )
          else
            vim.notify(
              "No file or directory selected",
              vim.log.levels.WARN,
              { title = "Path NOT copied to register", ft = "text" }
            )
          end
        end

        vim.keymap.set("n", "<leader>yy", function()
          copy_file_path({
            name = function(abs_path)
              return vim.fn.fnamemodify(abs_path, ":.")
            end,
            title = "Relative path copied to register",
          })
        end, { buffer = buf_id, desc = "Yank relative file path" })

        vim.keymap.set("n", "<leader>yY", function()
          copy_file_path()
        end, { buffer = buf_id, desc = "Yank absolute file path" })

        -- as described here https://github.com/nvim-mini/mini.nvim/discussions/936
        local function toggle_preview()
          local preview = MiniFiles.config.windows.preview
          local preview_next = not preview
          MiniFiles.config.windows.preview = preview_next
          MiniFiles.trim_right()
          MiniFiles.refresh({
            -- NOTE: Should be explicitly set
            windows = { preview = preview_next },
          })
          -- NOTE: Should be called after `MiniFiles.refresh`
          if preview then
            local branch = MiniFiles.get_explorer_state().branch
            -- My small modification, to prevent erroring out on single column in explorer removal
            if #branch > 1 then
              table.remove(branch)
              MiniFiles.set_branch(branch)
            end
          end
        end
        vim.keymap.set("n", "<C-p>", toggle_preview, { buffer = buf_id, desc = "Toggle file preview" })

        -- shadows global <leader>o for mini.files on opened mini.files
        vim.keymap.set("n", "<leader>o", function()
          local curr_entry = MiniFiles.get_fs_entry()
          if curr_entry then
            local cmd
            if vim.fn.has("mac") == 1 then
              cmd = { "open", curr_entry.path }
            else -- Linux
              cmd = { "xdg-open", curr_entry.path }
            end
            vim.system(cmd, { stdout = false, stderr = false })
          else
            vim.notify("No file or directory selected", vim.log.levels.WARN)
          end
        end, { buffer = buf_id, desc = "Open in the system app" })
      end,
    })
  end,
}
