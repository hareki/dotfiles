return {
  Catppuccin(function(palette)
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
      local ui = require('utils.ui')
      local preview_cols = ui.side_size('side_panel', 'sm')

      return {
        explorer = {
          hidden = false,
          indent_markers = false,
          flatten_dirs = true,
          position = 'right',
          width = preview_cols,
          view_mode = 'tree',

          icons = {
            folder_closed = Icons.file_tree.folder,
            folder_open = Icons.file_tree.folder_open,
          },
        },
      }
    end,

    config = function(_, opts)
      local codediff_utils = require('plugins.features.git.codediff-nvim.utils')
      local group = vim.api.nvim_create_augroup('git.codediff.restore_focus', { clear = true })

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
