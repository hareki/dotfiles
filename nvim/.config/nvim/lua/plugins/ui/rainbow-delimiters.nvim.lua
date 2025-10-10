return {
  require('utils.ui').catppuccin(function(palette)
    return {
      RainbowDelimiterGreen = {
        fg = palette.pink, -- avoid string color
      },
    }
  end),
  {
    'https://gitlab.com/HiPhish/rainbow-delimiters.nvim',
    event = 'VeryLazy',
  },
}
