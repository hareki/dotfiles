return {
  'chrisgrieser/nvim-spider',
  keys = {
    {
      'w',
      "<CMD>lua require('spider').motion('w')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider: Word Forward',
    },
    {
      'e',
      "<CMD>lua require('spider').motion('e')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider: Word End',
    },
    {
      'b',
      "<CMD>lua require('spider').motion('b')<CR>",
      mode = { 'n', 'o', 'x' },
      desc = 'Spider: Word Backward',
    },
  },
}
