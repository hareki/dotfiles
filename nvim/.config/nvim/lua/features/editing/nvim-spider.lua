local prefix = 'Spider: '

--- @module 'spider'
local spider = Defer.on_exported_call('spider')

return {
  'chrisgrieser/nvim-spider',
  keys = {
    {
      'w',
      function()
        spider.motion('w')
      end,
      mode = { 'n', 'o', 'x' },
      desc = prefix .. 'Word Forward',
    },
    {
      'e',
      function()
        spider.motion('e')
      end,
      mode = { 'n', 'o', 'x' },
      desc = prefix .. 'Word End',
    },
    {
      'b',
      function()
        spider.motion('b')
      end,
      mode = { 'n', 'o', 'x' },
      desc = prefix .. 'Word Backward',
    },
  },
}
