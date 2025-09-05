return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
  },
  keys = {
    { '<A-m>', '<CMD>TmuxNavigateLeft<CR>', desc = 'Navigate Window Left' },
    { '<A-n>', '<CMD>TmuxNavigateDown<CR>', desc = 'Navigate Window Down' },
    { '<A-e>', '<CMD>TmuxNavigateUp<CR>', desc = 'Navigate Window Up' },
    { '<A-i>', '<CMD>TmuxNavigateRight<CR>', desc = 'Navigate Window Right' },
  },
}
