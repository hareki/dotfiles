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
      -- HACK: Modicator's own map matches whole mode() codes only, sending every code it doesn't
      -- list (ic, Rv, cv, !, r, rm, ...) to NormalMode; resolve through UI.mode so the line
      -- number matches lualine's mode pill
      --- @diagnostic disable-next-line: duplicate-set-field
      modicator.hl_name_from_mode = function(mode)
        return UI.mode.name(mode) .. 'Mode'
      end
      modicator.setup(opts)
    end,
  },
}
