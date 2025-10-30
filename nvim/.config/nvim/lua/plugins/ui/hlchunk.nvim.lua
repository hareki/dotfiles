return {
  {
    'shellRaining/hlchunk.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = function()
      local palette = require('catppuccin.palettes').get_palette()
      return {
        chunk = {
          enable = true,
          style = {
            { fg = palette.surface2 },
            { fg = palette.red },
          },
          duration = 200,
          delay = 210,
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
