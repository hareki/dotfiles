return {
  UI.catppuccin(function(palette)
    local pill_bg = UI.color.blend_hex(palette.base, palette.blue)

    return {
      UfoFoldPillOuter = { fg = pill_bg },
      UfoFoldPillInner = { fg = palette.blue, bg = pill_bg },
    }
  end),

  UI.which_key({
    rules = { pattern = 'fold', icon = Conf.icons.actions.FOLD, color = 'blue' },
  }),

  {
    'kevinhwang91/nvim-ufo',
    event = 'BufReadPost', -- Prevent built-in folding flashing
    dependencies = { 'kevinhwang91/promise-async' },
    init = function()
      local opt = vim.opt

      opt.foldlevel = 99
      opt.foldlevelstart = 99
    end,

    keys = {
      {
        'zh',
        function()
          local ufo = require('ufo')
          local preview_win_id = ufo.peekFoldedLinesUnderCursor()
          if preview_win_id == nil then
            return
          end

          -- The float is up by now, and ufo shows only its own reused preview buffer in it,
          -- so the map can stay on that buffer between peeks
          vim.keymap.set('n', '<Esc>', function()
            local ufo_preview = require('ufo.preview')
            ufo_preview.close()
          end, {
            buffer = vim.api.nvim_win_get_buf(preview_win_id),
            desc = 'Close Fold Preview',
          })
        end,
        desc = 'Peek Folded Lines',
      },
    },

    opts = function()
      local utils = require('chrome.nvim-ufo.utils')

      return {
        fold_virt_text_handler = utils.fold_text_handler,
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
  },
}
