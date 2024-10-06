return {
  "nvim-lualine/lualine.nvim",
  keys = {
    {
      "<leader>ul1",
      function()
        Util.git.set_branch_name_format(Constant.git.BRANCH_FORMATS.TASK_ID_ONLY)
      end,
      desc = "Set task id only branch name format",
    },
    {
      "<leader>ul2",
      function()
        Util.git.set_branch_name_format(Constant.git.BRANCH_FORMATS.TASK_ID_AND_NAME)
      end,
      desc = "Set task id and task name branch name format",
    },
    {
      "<leader>ul3",
      function()
        Util.git.set_branch_name_format(Constant.git.BRANCH_FORMATS.TASK_ID_AND_AUTHOR)
      end,
      desc = "Set task id and author branch name format",
    },
  },
  opts = function(_, opts)
    local icons = LazyVim.config.icons

    opts.options.section_separators = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }

    local extensions = opts.extensions
    for i = #extensions, 1, -1 do
      if extensions[i] == "neo-tree" then
        table.remove(extensions, i)
      end
    end

    -- Update lualine_b section with formatted branch name
    opts.sections.lualine_b = {
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
    }

    -- table.insert(opts.sections.lualine_c, 1, {
    --   get_git_repo_name,
    --   icon = "󱉭",
    -- })

    table.insert(opts.sections.lualine_c, 1, {
      function()
        local repo = Util.git.get_repo_name()
        return repo and ("󱉭 " .. repo) or "󱉭"
      end,
    })

    -- ===== SECTION X ====
    Util.remove_lualine_component("diff", opts.sections.lualine_x)

    -- ===== SECTION Y ====
    opts.sections.lualine_y = {
      {
        "diagnostics",
        symbols = {
          error = icons.diagnostics.Error,
          warn = icons.diagnostics.Warn,
          info = icons.diagnostics.Info,
          hint = icons.diagnostics.Hint,
        },
        always_visible = true,
      },
    }

    -- ===== SECTION Z ====
    opts.sections.lualine_z = {
      { "location", padding = { left = 1, right = 1 }, separator = "|" },
      { "progress", padding = { left = 1, right = 1 }, separator = "|" },
    }
  end,
}
