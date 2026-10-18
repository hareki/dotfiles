-- [[ Cursor Line Number Mode Indicator ]]
return {
  -- Applied before setup(), and modicator only fills *Mode groups that are still empty, so its
  -- fallback links and lualine integration (lualine's theme is reset) never override these
  UI.catppuccin(function(palette)
    local highlights = {}
    for name, color in pairs(UI.mode.colors) do
      highlights[name .. 'Mode'] = { fg = palette[color] }
    end
    return highlights
  end, 'modicator.nvim'),

  {
    'mawkler/modicator.nvim',
    event = 'VeryLazy',
    config = function(_, opts)
      local modicator = require('modicator')
      local utils = require('chrome.modicator-nvim.utils')

      utils.patch(modicator)
      modicator.setup(opts)
    end,
  },
}
