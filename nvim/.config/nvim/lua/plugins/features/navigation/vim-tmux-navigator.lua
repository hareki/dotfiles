return {
  'christoomey/vim-tmux-navigator',
  cmd = { 'TmuxNavigateLeft', 'TmuxNavigateDown', 'TmuxNavigateUp', 'TmuxNavigateRight' },
  keys = function()
    return {
      { '<A-m>', vim.cmd.TmuxNavigateLeft, mode = { 'n', 't' }, desc = 'To Window Left' },
      { '<A-n>', vim.cmd.TmuxNavigateDown, mode = { 'n', 't' }, desc = 'To Window Below' },
      { '<A-e>', vim.cmd.TmuxNavigateUp, mode = { 'n', 't' }, desc = 'To Window Above' },
      { '<A-i>', vim.cmd.TmuxNavigateRight, mode = { 'n', 't' }, desc = 'To Window Right' },
    }
  end,
}
