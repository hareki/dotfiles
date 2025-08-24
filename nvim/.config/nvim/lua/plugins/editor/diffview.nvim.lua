return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  keys = {
    {
      '<leader>dc',
      '<cmd>DiffviewOpen<cr>',
      desc = "current line's commit",
      silent = true,
    },
    {
      '<leader>dl',
      function()
        local git = require('utils.git')
        local current_commit = git.get_current_line_commit()

        if not current_commit then
          notifier.warn('No commit history for this line')
          return
        end

        git.diff_parent(current_commit)
      end,
      desc = "current line's commit",
    },
    {
      '<leader>dt',
      function()
        require('utils.git').diff_parent()
      end,
    },
  },

  opts = function()
    local icons = require('configs.icons')
    local panel_win_config = {
      position = 'bottom',
      height = 12,
    }
    return {
      enhanced_diff_hl = true,
      icons = {
        folder_closed = icons.explorer.folder,
        folder_open = icons.explorer.folder_open,
      },
      signs = {
        fold_closed = icons.explorer.collapsed,
        fold_open = icons.explorer.expanded,
      },
      file_panel = {
        win_config = panel_win_config,
      },
      file_history_panel = {
        win_config = panel_win_config,
      },
      view = {
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
      hooks = {
        view_opened = function(view)
          if view.class:name() == 'DiffView' then
            require('diffview.actions').toggle_files()
          end
        end,
      },
    }
  end,
}
