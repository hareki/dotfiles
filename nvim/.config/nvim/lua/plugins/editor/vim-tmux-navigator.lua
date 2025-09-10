return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
  },
  keys = {
    { '<A-m>', '<CMD>TmuxNavigateLeft<CR>', desc = 'Navigate Window Left', mode = { 'n', 't' } },
    { '<A-n>', '<CMD>TmuxNavigateDown<CR>', desc = 'Navigate Window Down', mode = { 'n', 't' } },
    { '<A-e>', '<CMD>TmuxNavigateUp<CR>', desc = 'Navigate Window Up', mode = { 'n', 't' } },
    { '<A-i>', '<CMD>TmuxNavigateRight<CR>', desc = 'Navigate Window Right', mode = { 'n', 't' } },
  },
}
