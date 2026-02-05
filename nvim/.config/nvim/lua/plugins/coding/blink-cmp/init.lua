local limit = require('plugins.coding.blink-cmp.config.limit')

return {
  Catppuccin(function(palette)
    return {
      BlinkCmpKindRenderMD = { fg = palette.text },
      BlinkCmpKindHistory = { fg = palette.mauve },
      BlinkCmpLabelMatch = { fg = palette.blue },
      BlinkCmpKindRipgrepGit = { fg = palette.red },
      BlinkCmpLabel = { fg = palette.text },
      BlinkCmpKindVariable = { link = '@variable' },
    }
  end),
  {
    'saghen/blink.compat',
    opts = {},
  },
  {
    'fang2hou/blink-copilot',
    opts = function()
      local icons = require('configs.icons')

      return {
        max_completions = limit.copilot_max_items,
        max_attempts = limit.copilot_max_items + 1,
        kind_name = 'Copilot',
        kind_icon = icons.kinds.Copilot,
        kind_hl = 'BlinkCmpKindCopilot',
        debounce = 200,
        auto_refresh = {
          backward = true,
          forward = true,
        },
      }
    end,
  },
  {
    'saghen/blink.cmp',
    version = '*', -- Use a release tag to download pre-built binaries
    event = { 'InsertEnter', 'CmdLineEnter' },
    dependencies = {
      'windwp/nvim-autopairs',
      'dmitmel/cmp-cmdline-history',

      'zbirenbaum/copilot.lua',
      'fang2hou/blink-copilot',

      'xieyonn/blink-cmp-dat-word',
      'hareki/blink-ripgrep.nvim',
      'disrupted/blink-cmp-conventional-commits',
    },
    opts = function()
      local completion = require('plugins.coding.blink-cmp.config.completion')
      local keymap = require('plugins.coding.blink-cmp.config.keymap')
      local sources = require('plugins.coding.blink-cmp.config.sources')
      local appearance = require('plugins.coding.blink-cmp.config.appearance')

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
