return {
  'kevinhwang91/nvim-ufo',
  event = 'LazyFile',
  dependencies = { 'kevinhwang91/promise-async' },
  keys = {
    {
      'zh',
      function()
        local preview_win_id = require('ufo').peekFoldedLinesUnderCursor()
        if preview_win_id == nil then
          return
        end

        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          vim.keymap.set('n', '<Esc>', function()
            require('ufo.preview').close()
          end, { buffer = buf, silent = true, desc = 'Close Fold Preview' })
        end)
      end,
      desc = 'Peek Folded Lines',
    },
  },
  opts = {
    -- https://github.com/kevinhwang91/nvim-ufo/blob/1ebb9ea3507f3a40ce8b0489fb259ab32b1b5877/README.md?plain=1#L97
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
    preview = {
      win_config = {
        winblend = 0,
      },
    },
  },
}
