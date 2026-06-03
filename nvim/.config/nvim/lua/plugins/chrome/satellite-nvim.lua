-- [[ Neovim Scrollbar ]]
return {
  Catppuccin(function(palette)
    return {
      SatelliteBar = { bg = palette.surface1 },
      SatelliteSearch = { fg = palette.yellow },
      SatelliteSearchCurrent = { fg = palette.yellow },
      SatelliteDiagnosticError = { link = 'DiagnosticSignError' },
      SatelliteDiagnosticWarn = { link = 'DiagnosticSignWarn' },
      SatelliteDiagnosticInfo = { link = 'DiagnosticSignInfo' },
      SatelliteDiagnosticHint = { link = 'DiagnosticSignHint' },
    }
  end),

  {
    'hareki/satellite.nvim',
    lazy = false,
    priority = Priority.CHROME,
    opts = {
      current_only = false,
      floating = true,
      winblend = 0,
      excluded_filetypes = {
        'snacks_picker_list',
        'TelescopeResults',
      },
      handlers = {
        cursor = { enable = false },
        gitsigns = { enable = false },
        marks = { enable = false },
      },
    },
  },
}
