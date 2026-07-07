-- [[ Neovim Scrollbar ]]
return {
  UI.catppuccin(function(palette)
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
    priority = Conf.priority.CHROME,
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
    config = function(_, opts)
      -- PERF: Disable satellite mouse handler by occupying the keymap
      vim.keymap.set(
        { 'n', 'v', 'o', 'i' },
        '<leftmouse>',
        '<leftmouse>',
        { desc = 'Disable Satellite Mouse Handler' }
      )

      local satellite = require('satellite')
      satellite.setup(opts)
    end,
  },
}
