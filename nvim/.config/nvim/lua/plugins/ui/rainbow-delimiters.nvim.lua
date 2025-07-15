return {
  {
    'hiphish/rainbow-delimiters.nvim',
    config = function()
      local palette = Util.palette()
      Util.highlights({
        -- Setting different color from "String" highlight group to avoid confusion
        RainbowDelimiterGreen = { fg = palette.rosewater },
      })
    end,
  },
}
