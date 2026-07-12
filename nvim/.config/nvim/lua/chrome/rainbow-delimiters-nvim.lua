return {
  UI.catppuccin(function(palette)
    return {
      RainbowDelimiterGreen = {
        fg = palette.pink, -- Avoid string color
      },
    }
  end),

  {
    'HiPhish/rainbow-delimiters.nvim',
    event = 'BufReadPost',
  },
}
