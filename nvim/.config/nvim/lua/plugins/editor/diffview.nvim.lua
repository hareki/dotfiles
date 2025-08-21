return {
  {
    'sindrets/diffview.nvim',
    cmd = 'DiffviewOpen',
    keys = {
      {
        '<leader>gdl',
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
        '<leader>gdt',
        function()
          require('utils.git').diff_parent()
        end,
      },
    },
  },
}
