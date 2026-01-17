return {
  require('utils.ui').catppuccin(function(palette)
    return {
      RainbowDelimiterGreen = {
        fg = palette.pink, -- Avoid string color
      },
    }
  end),
  {
    'https://gitlab.com/HiPhish/rainbow-delimiters.nvim',
    event = 'BufReadPost',
  },
}
