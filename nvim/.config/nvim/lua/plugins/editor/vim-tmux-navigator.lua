return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
  },
  keys = function()
    return {
      { '<A-m>', '<CMD>TmuxNavigateLeft<CR>', mode = { 'n', 't' }, desc = 'Navigate Window Left' },
      { '<A-n>', '<CMD>TmuxNavigateDown<CR>', mode = { 'n', 't' }, desc = 'Navigate Window Down' },
      { '<A-e>', '<CMD>TmuxNavigateUp<CR>', mode = { 'n', 't' }, desc = 'Navigate Window Up' },
      {
        '<A-i>',
        '<CMD>TmuxNavigateRight<CR>',
        mode = { 'n', 't' },
        desc = 'Navigate Window Right',
      },
    }
  end,
}
