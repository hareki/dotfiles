return {
  'hareki/tiny-code-action.nvim',
  event = 'LspAttach',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hareki/snacks.nvim',
  },

  opts = function()
    return {
      backend = 'delta',
      picker = {
        'snacks',
        opts = {
          source = 'buffer',
          win = {
            preview = {
              title = Conf.Picker.PREVIEW_TITLE,
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
