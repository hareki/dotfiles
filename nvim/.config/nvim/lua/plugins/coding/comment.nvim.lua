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
    local ts_context = require('ts_context_commentstring.integrations.comment_nvim')
    return {
      pre_hook = ts_context.create_pre_hook(),
    }
  end,
}
