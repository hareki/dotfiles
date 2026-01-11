return {
  'numToStr/comment.nvim',
  main = 'Comment',
  dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
  keys = function()
    return {
      { 'gc', mode = { 'n', 'x' }, desc = 'Toggle Comment Linewise' },
      { 'gb', mode = { 'n', 'x' }, desc = 'Toggle Comment Blockwise' },
      { 'gcc', desc = 'Toggle Comment Line' },
      { 'gbc', desc = 'Toggle Comment Block' },
    }
  end,
  opts = function()
    return {
      pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
    }
  end,
}
