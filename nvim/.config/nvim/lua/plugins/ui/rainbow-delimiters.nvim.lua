return {
  {
    'hiphish/rainbow-delimiters.nvim',
    config = function()
      local palette = require('utils.ui').get_palette()
      require('utils.ui').set_highlights({
        -- Setting different color from "String" highlight group to avoid confusion
        RainbowDelimiterGreen = { fg = palette.rosewater },
      })
    end,
  },
}
