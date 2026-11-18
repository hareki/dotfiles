return {
  UI.catppuccin(function(palette)
    return {
      LazyH1 = { bg = palette.blue, fg = palette.base },
      LazyDir = { fg = palette.blue },
      LazyUrl = { fg = palette.blue },
      LazyReasonStart = { fg = palette.blue },
      LazySpecial = { fg = palette.blue },
      LazyProgressDone = { fg = palette.blue },
    }
  end),

  -- Its bootstrap clone (config/lazy/utils.lua) takes the same fork
  { 'hareki/lazy.nvim' },
}
