return {
  'rachartier/tiny-code-action.nvim',
  event = 'LspAttach',

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
