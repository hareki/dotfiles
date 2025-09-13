return {
  require('utils.ui').catppuccin(function(palette)
    return {
      RainbowDelimiterGreen = {
        fg = palette.pink, -- avoid string color
      },
    }
  end),
  {
    'hiphish/rainbow-delimiters.nvim',
    event = 'VeryLazy',
  },
}
