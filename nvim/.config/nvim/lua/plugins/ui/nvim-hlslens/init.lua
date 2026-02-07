return {
  Catppuccin(function(palette)
    local utils = require('utils.ui')
    local near_pill_bg = utils.blend_hex(palette.peach, palette.base)
    local far_pill_bg = utils.blend_hex(palette.overlay1, palette.base)

    return {
      HlSearchLensPillNearOuter = { fg = near_pill_bg },
      HlSearchLensPillNearInner = { fg = palette.peach, bg = near_pill_bg },
      HlSearchLensPillOuter = { fg = far_pill_bg },
      HlSearchLensPillInner = { fg = palette.overlay1, bg = far_pill_bg },
    }
  end),

  {
    'kevinhwang91/nvim-hlslens',
    event = 'VeryLazy',
    keys = {
      {
        'n',
        function()
          vim.cmd.normal({ vim.v.count1 .. 'n', bang = true })
          require('hlslens').start()
        end,
        desc = 'Next Search Result',
      },

      {
        'N',
        function()
          vim.cmd.normal({ vim.v.count1 .. 'N', bang = true })
          require('hlslens').start()
        end,
        desc = 'Previous Search Result',
      },
    },
    opts = function()
      local utils = require('plugins.ui.nvim-hlslens.utils')

      return {
        override_lens = utils.search_text_handler,
      }
    end,
  },
}
