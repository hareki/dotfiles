return {
  'christoomey/vim-tmux-navigator',
  cmd = { 'TmuxNavigateLeft', 'TmuxNavigateDown', 'TmuxNavigateUp', 'TmuxNavigateRight' },
  keys = {
    { '<A-m>', '<cmd>TmuxNavigateLeft<cr>', mode = { 'n', 't' }, desc = 'Go to Left Window' },
    { '<A-n>', '<cmd>TmuxNavigateDown<cr>', mode = { 'n', 't' }, desc = 'Go to Lower Window' },
    { '<A-e>', '<cmd>TmuxNavigateUp<cr>', mode = { 'n', 't' }, desc = 'Go to Upper Window' },
    { '<A-i>', '<cmd>TmuxNavigateRight<cr>', mode = { 'n', 't' }, desc = 'Go to Right Window' },
  },
}
