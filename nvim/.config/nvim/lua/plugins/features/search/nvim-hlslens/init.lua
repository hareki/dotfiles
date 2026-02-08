return {
  Catppuccin(function(palette, _)
    local utils = require('utils.ui')
    local near_pill_bg = utils.blend_hex(palette.base, palette.yellow)
    local far_pill_bg = utils.blend_hex(palette.base, palette.overlay1)

    return {
      HlSearchLensPillNearOuter = { fg = near_pill_bg },
      HlSearchLensPillNearInner = { fg = palette.yellow, bg = near_pill_bg },
      HlSearchLensPillOuter = { fg = far_pill_bg },
      HlSearchLensPillInner = { fg = palette.overlay1, bg = far_pill_bg },

      CurSearch = { bg = palette.yellow, fg = palette.mantle },
      IncSearch = { link = 'CurSearch' },
      Search = { bg = near_pill_bg, fg = palette.yellow },
    }
  end),

  {
    'kevinhwang91/nvim-hlslens',
    event = 'VeryLazy',
    keys = function()
      local utils = require('plugins.features.search.nvim-hlslens.utils')

      return {
        {
          'n',
          function()
            utils.navigate('n')
          end,
          desc = 'Next Search Result',
        },
        {
          'N',
          function()
            utils.navigate('N')
          end,
          desc = 'Previous Search Result',
        },
      }
    end,

    opts = function()
      local utils = require('plugins.features.search.nvim-hlslens.utils')

      -- HACK: Intercept nohlsearch call to re-enable Snacks.words
      local original_nohlsearch = vim.cmd.nohlsearch
      vim.cmd.nohlsearch = function()
        original_nohlsearch()
        Snacks.words.enable()
        Snacks.words.update()
      end

      return {
        enable_incsearch = false, -- Do not interfere when doing substitution
        override_lens = utils.search_text_handler,
      }
    end,
  },
}
