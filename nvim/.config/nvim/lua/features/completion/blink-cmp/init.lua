return {
  UI.catppuccin(function(palette)
    return {
      BlinkCmpKindRenderMD = { fg = palette.text },
      BlinkCmpKindHistory = { fg = palette.mauve },
      BlinkCmpLabelMatch = { fg = palette.blue },
      BlinkCmpKindRipgrepGit = { fg = palette.red },
      BlinkCmpLabel = { fg = palette.text },
      BlinkCmpKindVariable = { link = '@variable' },
    }
  end, 'blink.cmp'),

  {
    'saghen/blink.compat',
    opts = {},
  },
  {
    'saghen/blink.cmp',
    version = '*', -- Use a release tag to download pre-built binaries
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'windwp/nvim-autopairs',
      'dmitmel/cmp-cmdline-history',

      'xieyonn/blink-cmp-dat-word',
      'hareki/blink-ripgrep.nvim',
      'disrupted/blink-cmp-conventional-commits',
    },

    opts = function()
      local completion = require('features.completion.blink-cmp.config.completion')
      local keymap = require('features.completion.blink-cmp.config.keymap')
      local sources = require('features.completion.blink-cmp.config.sources')
      local appearance = require('features.completion.blink-cmp.config.appearance')

      return {
        fuzzy = { implementation = 'prefer_rust_with_warning' },
        signature = { enabled = true, window = { border = 'rounded' } },
        appearance = appearance.default,

        sources = sources.default,
        completion = completion.default,
        keymap = keymap.default,

        cmdline = {
          enabled = true,

          sources = sources.cmdline,
          completion = completion.cmdline,
          keymap = keymap.cmdline,
        },
      }
    end,
  },
}
