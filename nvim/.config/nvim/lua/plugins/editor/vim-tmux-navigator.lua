return {
  'christoomey/vim-tmux-navigator',
  cmd = { 'TmuxNavigateLeft', 'TmuxNavigateDown', 'TmuxNavigateUp', 'TmuxNavigateRight' },
  keys = function()
    return {
      { '<A-m>', '<CMD>TmuxNavigateLeft<CR>', mode = { 'n', 't' }, desc = 'To Window Left' },
      { '<A-n>', '<CMD>TmuxNavigateDown<CR>', mode = { 'n', 't' }, desc = 'To Window Below' },
      { '<A-e>', '<CMD>TmuxNavigateUp<CR>', mode = { 'n', 't' }, desc = 'To Window Above' },
      { '<A-i>', '<CMD>TmuxNavigateRight<CR>', mode = { 'n', 't' }, desc = 'To Window Right' },
    }
  end,
}
