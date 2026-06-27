return {
  "nvim-mini/mini.files",
  lazy = true,
  opts = function(_, opts)
    -- default config: https://github.com/nvim-mini/mini.files#default-config
    opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
      -- default is "@"
      reveal_cwd = ";",
      -- default is "=",
      synchronize = "<CR>",
    })
    -- Whether to use for editing directories.
    -- I prefer using Oil as a dir viewer, this is commented out just for the reference
    -- opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
    --   use_as_default_explorer = true,
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
        local FileUtils = require("util.files")

        require("which-key").add {
          { "<leader>y", group = "Yank file path", buffer = buf_id },
        }

        -- apparently, I'm too used to enter being sync now.
        -- enter is also "go_in_plus", in addition to the default "L"
        -- vim.keymap.set("n", "<cr>", function()
        --   MiniFiles.go_in({
        --     close_on_file = true,
        --   })
        -- end, { buffer = buf_id, desc = "Yank relative file path" })

        -- syncing on save
        vim.bo[buf_id].buftype = "acwrite"
        vim.api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buf_id,
          callback = function()
            MiniFiles.synchronize()
          end,
        })

        ---Get absolute path of the file under the current cursor in normal mode in mini.files
        ---@return string
        local function get_selection_path()
          local curr_entry = MiniFiles.get_fs_entry()
          if not curr_entry then
            error("No file or directory selected")
          end
          return curr_entry.path
        end

        vim.keymap.set("n", "<esc><esc>", MiniFiles.close, { buffer = buf_id, desc = "Close" })

        vim.keymap.set("n", "<leader>yy", function()
          FileUtils.yank_relative_path(get_selection_path())
        end, { buffer = buf_id, desc = "Yank relative file path" })

        vim.keymap.set("n", "<leader>yY", function()
          FileUtils.yank_absolute_path(get_selection_path())
        end, { buffer = buf_id, desc = "Yank absolute file path" })

        vim.keymap.set({ "n", "x" }, "<leader>yf", function()
          if vim.fn.mode() ~= "n" then
            FileUtils.copy_visual_selection_to_clipboard(function(lnum)
              local entry = MiniFiles.get_fs_entry(buf_id, lnum)
              return entry and entry.path
            end)
          else
            FileUtils.copy_files_to_clipboard { get_selection_path() }
          end
        end, { buffer = buf_id, desc = "Yank file(s) to system clipboard" })

        -- as described here https://github.com/nvim-mini/mini.nvim/discussions/936
        local function toggle_preview()
          local preview = MiniFiles.config.windows.preview
          local preview_next = not preview
          MiniFiles.config.windows.preview = preview_next
          MiniFiles.trim_right()
          MiniFiles.refresh {
            -- NOTE: Should be explicitly set
            windows = { preview = preview_next },
          }
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

        -- with shadowing shadows global <leader>o for mini.files on opened mini.files
        vim.keymap.set("n", "<leader>e", function()
          local abs_path = get_selection_path()
          FileUtils.open_file(abs_path)
        end, { buffer = buf_id, desc = "Open in the system app" })

        -- also shadows global <leader>O, this time for Oil this is for bulk creation of files and such
        vim.keymap.set("n", "<leader>O", function()
          local curr_entry = MiniFiles.get_fs_entry()
          if not curr_entry then
            vim.notify("No file or directory selected", vim.log.levels.WARN)
            return
          end
          vim.cmd(":Oil --float " .. vim.fn.fnamemodify(curr_entry.path, ":h"))
        end, { buffer = buf_id, desc = "Open selected directory in Oil" })

        -- reuse "open definition in VSplit" from our regular keymap in mini.files to open file in a VSplit
        vim.keymap.set("n", "g<C-v>", function()
          local curr_entry = MiniFiles.get_fs_entry()
          if curr_entry ~= nil and curr_entry.path then
            local keys = vim.api.nvim_replace_termcodes("<C-w>v", true, false, true)
            vim.api.nvim_feedkeys(keys, "nx", false)
            vim.cmd.edit(curr_entry.path)
          else
            vim.notify("No file or directory selected", vim.log.levels.WARN)
          end
        end, { buffer = buf_id, desc = "Open file in VSplit" })
      end,
    })
  end,
}
