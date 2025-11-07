return {
  {
    'numToStr/comment.nvim',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    main = 'Comment',
    event = 'VeryLazy',
    opts = function()
      return {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  },
}
