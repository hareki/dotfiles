return {
  'sindrets/diffview.nvim',
  cmd = 'DiffviewOpen',
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
    return {
      file_panel = {
        win_config = {
          position = 'right',
          width = 40,
        },
      },
      view = {

        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
      hooks = {
        view_opened = function()
          -- Toggle off the file panel when view initially opens
          require('diffview.actions').toggle_files()
        end,
      },
    }
  end,
}
