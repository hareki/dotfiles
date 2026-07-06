return {
  UI.catppuccin(function(palette)
    return {
      CodeDiffExplorerTreeGroup = { fg = palette.yellow },
      CodeDiffHistoryTitle = { fg = palette.yellow },
    }
  end),

  {
    'hareki/codediff.nvim',
    cmd = 'CodeDiff',
    keys = {
      {
        '<leader>g',
        '<cmd>CodeDiff<cr>',
        desc = 'CodeDiff: Open',
      },
    },

    opts = function()
      local preview_cols = UI.side_size('side_panel', 'sm')

      return {
        explorer = {
          hidden = false,
          indent_markers = false,
          flatten_dirs = true,
          focus_on_select = false,
          auto_open_on_cursor = true,
          position = 'right',
          width = preview_cols,
          view_mode = 'tree',

          icons = {
            folder_closed = Conf.icons.file_tree.FOLDER,
            folder_open = Conf.icons.file_tree.FOLDER_OPEN,
          },
        },
      }
    end,

    config = function(_, opts)
      local codediff_utils = require('features.git.codediff-nvim.utils')
      local group = vim.api.nvim_create_augroup('git.codediff.restore-focus', { clear = true })

      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeDiffFileSelect',
        callback = codediff_utils.remember_selection,
      })

      -- The diff tab's windows are destroyed (tabclose) before CodeDiffClose fires,
      -- so snapshot the modified pane's scroll/cursor while it is still alive.
      vim.api.nvim_create_autocmd('TabLeave', {
        group = group,
        callback = codediff_utils.capture_view,
      })

      -- On close, switch the initial tab's active window to the file that was last
      -- focused in codediff and restore its scroll position, so quitting feels like
      -- simply turning codediff off.
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'CodeDiffClose',
        callback = codediff_utils.restore_focus,
      })

      local codediff = require('codediff')
      codediff.setup(opts)
    end,
  },
}
