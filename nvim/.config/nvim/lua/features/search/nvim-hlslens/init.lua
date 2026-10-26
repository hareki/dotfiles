return {
  UI.catppuccin(function(palette)
    local near_pill_bg = UI.color.blend_hex(palette.base, palette.yellow)
    local far_pill_bg = UI.color.blend_hex(palette.base, palette.overlay1)

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
    keys = {
      {
        '<CR>',
        mode = 'c',
        desc = 'Execute Command Line',
      },
      {
        'n',
        function()
          local utils = require('features.search.nvim-hlslens.utils')
          utils.navigate('n')
        end,
        desc = 'Next Search Result',
      },
      {
        'N',
        function()
          local utils = require('features.search.nvim-hlslens.utils')
          utils.navigate('N')
        end,
        desc = 'Previous Search Result',
      },
    },

    opts = function()
      local utils = require('features.search.nvim-hlslens.utils')
      return {
        enable_incsearch = false, -- Do not interfere when doing substitution
        override_lens = utils.search_text_handler,
      }
    end,
  },
}
