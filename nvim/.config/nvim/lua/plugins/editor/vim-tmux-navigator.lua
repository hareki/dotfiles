return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
  },
  keys = {
    { '<A-m>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate Window Left' },
    { '<A-n>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate Window Down' },
    { '<A-e>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate Window Up' },
    { '<A-i>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate Window Right' },
  },
}
