return {
  'kevinhwang91/nvim-ufo',
  event = 'VeryLazy',
  dependencies = { 'kevinhwang91/promise-async' },
  keys = function()
    return {
      {
        'zh',
        function()
          local ufo = require('ufo')
          local preview_win_id = ufo.peekFoldedLinesUnderCursor()
          if preview_win_id == nil then
            return
          end

          vim.schedule(function()
            if not vim.api.nvim_win_is_valid(preview_win_id) then
              return
            end

            local preview_buf = vim.api.nvim_win_get_buf(preview_win_id)
            local function clear_mapping()
              pcall(vim.keymap.del, 'n', '<Esc>', { buffer = preview_buf })
            end

            clear_mapping()

            vim.keymap.set('n', '<Esc>', function()
              clear_mapping()
              local ufo_preview = require('ufo.preview')
              ufo_preview.close()
            end, { buffer = preview_buf, desc = 'Close Fold Preview' })

            vim.api.nvim_create_autocmd('BufWipeout', {
              buffer = preview_buf,
              once = true,
              callback = clear_mapping,
            })

            vim.api.nvim_create_autocmd('WinClosed', {
              pattern = tostring(preview_win_id),
              once = true,
              callback = clear_mapping,
            })
          end)
        end,
        desc = 'Peek Folded Lines',
      },
    }
  end,

  opts = function()
    return {
      -- https://github.com/kevinhwang91/nvim-ufo/blob/1ebb9ea3507f3a40ce8b0489fb259ab32b1b5877/README.md?plain=1#L97
      provider_selector = function()
        return { 'treesitter', 'indent' }
      end,
      preview = {
        win_config = {
          winblend = 0,
        },
      },
    }
  end,
}
