return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
  },
  keys = {
    { '<A-m>', '<cmd>TmuxNavigateLeft<cr>' },
    { '<A-n>', '<cmd>TmuxNavigateDown<cr>' },
    { '<A-e>', '<cmd>TmuxNavigateUp<cr>' },
    { '<A-i>', '<cmd>TmuxNavigateRight<cr>' },
  },
}
