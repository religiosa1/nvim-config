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
    -- Whether to use for editing directories
    -- Disabled by default in LazyVim because neo-tree is used for that
    -- We need to diable neo-tree first though
    -- opts.options.use_as_default_explorer = false
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
        local mini_files = require("mini.files")
        local buf_id = args.data.buf_id

        require("which-key").add({
          { "<leader>y", group = "Yank file path", buffer = buf_id },
        })

        local function copy_file_path(args)
          local curr_entry = mini_files.get_fs_entry()
          if curr_entry then
            local relative_path
            if args ~= nil and type(args.name) == "function" then
              relative_path = args.name(curr_entry.path)
            else
              relative_path = curr_entry.path
            end
            vim.fn.setreg("+", relative_path)
            vim.notify(relative_path, vim.log.levels.INFO, { title = "Path copied to register", ft = "text" })
          else
            vim.notify("No file or directory selected", vim.log.levels.INFO,
              { title = "Path NOT copied to register", ft = "text" })
          end
        end

        vim.keymap.set(
          "n",
          "<leader>yy",
          function()
            copy_file_path {
              name = function(abs_path) return vim.fn.fnamemodify(abs_path, ":.") end,
            }
          end,
          { buffer = buf_id, desc = "Copy relative file path" }
        )

        vim.keymap.set(
          "n",
          "<leader>yY",
          function()
            copy_file_path()
          end,
          { buffer = buf_id, desc = "Copy absolute file path" }
        )

        vim.keymap.set(
          "n",
          "<leader>o",
          function()
            local curr_entry = mini_files.get_fs_entry()
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
          end,
          { buffer = buf_id, desc = "Open in the system app" }
        )
      end,
    })
  end,
}
