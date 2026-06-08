local prefix = 'Spider: '

return {
  'chrisgrieser/nvim-spider',
  keys = function()
    return {
      {
        'w',
        function()
          local spider = require('spider')
          spider.motion('w')
        end,
        mode = { 'n', 'o', 'x' },
        desc = prefix .. 'Word Forward',
      },
      {
        'e',
        function()
          local spider = require('spider')
          spider.motion('e')
        end,
        mode = { 'n', 'o', 'x' },
        desc = prefix .. 'Word End',
      },
      {
        'b',
        function()
          local spider = require('spider')
          spider.motion('b')
        end,
        mode = { 'n', 'o', 'x' },
        desc = prefix .. 'Word Backward',
      },
    }
  end,
}
