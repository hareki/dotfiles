return {
  {
    "nvim-lualine/lualine.nvim",
    keys = function(_, keys)
      local wk = require("which-key")
      local set_branch_name_format = Util.git.set_branch_name_format

      wk.add({
        { "<leader>ul", group = "Branch Format" },
      })

      return vim.list_extend(keys, {
        {
          "<leader>ul1",
          function()
            set_branch_name_format(Constant.git.branch_formats.TASK_ID_ONLY)
          end,
          desc = "Set task id only branch name format",
        },
        {
          "<leader>ul2",
          function()
            set_branch_name_format(Constant.git.branch_formats.TASK_ID_AND_NAME)
          end,
          desc = "Set task id and task name branch name format",
        },
        {
          "<leader>ul3",
          function()
            set_branch_name_format(Constant.git.branch_formats.TASK_ID_AND_AUTHOR)
          end,
          desc = "Set task id and author branch name format",
        },
      })
    end,

    opts = function(_, opts)
      local icons = LazyVim.config.icons
      local harpoon_indicators = {}
      local harpoon_active_indicators = {}

      for i = 1, 6 do
        table.insert(harpoon_indicators, tostring(i))
        table.insert(harpoon_active_indicators, "[" .. tostring(i) .. "]")
      end

      for i = #opts.extensions, 1, -1 do
        if opts.extensions[i] == "neo-tree" then
          table.remove(opts.extensions, i)
          break
        end
      end

      opts.options = vim.tbl_extend("force", opts.options, {
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      })

      local noice_command_status_index = 1
      Util.remove_lualine_component("diff", opts.sections.lualine_x)
      table.remove(opts.sections.lualine_x, noice_command_status_index)

      opts.sections = vim.tbl_extend("force", opts.sections, {
        lualine_b = {
          {
            "branch",
            fmt = Util.git.format_branch_name,
          },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },

        lualine_c = {
          {
            function()
              local repo = Util.git.get_repo_name()
              return repo and ("󱉭 " .. repo) or "󱉭"
            end,
          },
          {
            "harpoon2",
            icon = "󰀱",
            indicators = harpoon_indicators,
            active_indicators = harpoon_active_indicators,
          },
        },

        lualine_y = {
          {
            "diagnostics",
            sections = { "error", "warn", "info" },
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
            -- always_visible = true,
          },
          -- Acts as a padding that always there so that even if filetype icon is not visible, the filename will still have some padding
          {
            function()
              return " "
            end,
            padding = { left = 0, right = 0 },
          },
          {
            "filetype",
            icon_only = true,
            colored = false,
            padding = { left = 0, right = 0 },
          },
          {
            "filename",
            fmt = function(filename)
              return filename:gsub("neo%-tree filesystem %[%d+%]", "neo-tree.nvim")
            end,
            padding = { left = 0, right = 1 },
            symbols = {
              modified = " ",
              readonly = "󰌾",
            },
            separator = "|",
          },
          {
            function()
              return Util.buffer.count_file_buffers()
            end,
          },
        },

        lualine_z = {
          { "location", padding = { left = 1, right = 1 }, separator = "|" },
          { "progress", padding = { left = 1, right = 1 } },
        },
      })
    end,
  },
}
