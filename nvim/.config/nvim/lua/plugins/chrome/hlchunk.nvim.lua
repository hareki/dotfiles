return {
  {
    'shellRaining/hlchunk.nvim',
    event = 'VeryLazy',
    opts = function()
      local palettes = require('catppuccin.palettes')
      local palette = palettes.get_palette()

      return {
        chunk = {
          enable = true,
          style = {
            { fg = palette.overlay1 },
            { fg = palette.red },
          },
          duration = 200,
          delay = 200,
          chars = {
            horizontal_line = '─',
            vertical_line = '│',
            left_top = '╭',
            left_bottom = '╰',
            right_arrow = '─',
          },
        },
      }
    end,
  },
}
