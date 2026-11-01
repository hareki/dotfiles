return {
  'rachartier/tiny-code-action.nvim',
  opts = function()
    return {
      backend = 'delta',
      picker = {
        'snacks',
        opts = {
          win = {
            preview = {
              title = '', -- Drops the plugin's "Code Action Preview"
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
