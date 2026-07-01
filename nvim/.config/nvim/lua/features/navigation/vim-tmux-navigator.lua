return {
  'christoomey/vim-tmux-navigator',
  cmd = { 'TmuxNavigateLeft', 'TmuxNavigateDown', 'TmuxNavigateUp', 'TmuxNavigateRight' },
  keys = function()
    return {
      { '<A-m>', '<cmd>TmuxNavigateLeft<cr>', mode = { 'n', 't' }, desc = 'To Window Left' },
      { '<A-n>', '<cmd>TmuxNavigateDown<cr>', mode = { 'n', 't' }, desc = 'To Window Below' },
      { '<A-e>', '<cmd>TmuxNavigateUp<cr>', mode = { 'n', 't' }, desc = 'To Window Above' },
      { '<A-i>', '<cmd>TmuxNavigateRight<cr>', mode = { 'n', 't' }, desc = 'To Window Right' },
    }
  end,
}
