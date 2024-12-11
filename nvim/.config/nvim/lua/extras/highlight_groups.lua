return {
  setup = function()
    local palette = require("catppuccin.palettes").get_palette("mocha")

    Util.hls({
      Visual = { bold = false, bg = palette.surface1 },
      DocumentHighlight = { bg = "#373948" }, --#3b3d4d
      Cursor = { reverse = true },

      -- Remove the undercurl but keep spell checker on to use cmp-spell
      SpellBad = { underline = false },
      SpellCap = { underline = false },
      SpellRare = { underline = false },
      SpellLocal = { underline = false },

      LspReferenceText = { link = "DocumentHighlight" },
      LspReferenceRead = { link = "DocumentHighlight" },
      LspReferenceWrite = { link = "DocumentHighlight" },

      NormalFloat = { bg = "none" },
      FloatTitle = { fg = palette.blue },

      YankSystemHighlight = {
        fg = palette.base,
        bg = palette.yellow,
      },

      YankRegisterHighlight = {
        fg = palette.base,
        bg = palette.blue,
      },

      TabLine = {
        bg = palette.base,
        fg = palette.surface1,
      },
      TabLineFill = {
        bg = palette.base,
      },
    })
  end,
}
