return {
  {
    'numToStr/comment.nvim',
    main = 'Comment',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    keys = {
      { 'gc', desc = 'Toggle Comment Linewise', mode = { 'n', 'x' } },
      { 'gb', desc = 'Toggle Comment Blockwise', mode = { 'n', 'x' } },
      { 'gcc', desc = 'Toggle Comment Line' },
      { 'gbc', desc = 'Toggle Comment Block' },
    },
    opts = function()
      return {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  },
}
