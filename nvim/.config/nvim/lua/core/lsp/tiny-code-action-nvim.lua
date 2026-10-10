return {
  'rachartier/tiny-code-action.nvim',
  event = 'LspAttach',
  dependencies = {
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
              title = Conf.picker.PREVIEW_TITLE,
            },
          },
        },
      },
      backend_opts = {
        delta = {
          args = {}, -- No --line-numbers
        },
      },
    }
  end,
}
