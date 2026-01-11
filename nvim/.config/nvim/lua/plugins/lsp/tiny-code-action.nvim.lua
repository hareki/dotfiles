return {
  'hareki/tiny-code-action.nvim',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'folke/snacks.nvim' },
  },
  event = 'LspAttach',
  opts = function()
    local picker_config = require('configs.picker')
    return {
      backend = 'delta',
      picker = {
        'snacks',
        opts = {
          source = 'buffer',
          win = {
            preview = {
              title = picker_config.preview_title,
            },
          },
        },
      },
      backend_opts = {
        delta = {
          header_lines_to_remove = 4,
          args = {},
        },
      },
    }
  end,
}
