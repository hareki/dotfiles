local colors = require("catppuccin.palettes").get_palette("mocha")

local custom_highlights = {
  -- Set undercurl color of misspelled / unknown words as diagnostic's
  -- SpellBad = { link = "LspDiagnosticsUnderlineHint" },
  -- SpellCap = { link = "LspDiagnosticsUnderlineHint" },
  -- SpellRare = { link = "LspDiagnosticsUnderlineHint" },
  -- SpellLocal = { link = "LspDiagnosticsUnderlineHint" },

  -- Remove the undercurl but keep spell checker on to use cmp-spell
  SpellBad = { underline = false },
  SpellCap = { underline = false },
  SpellRare = { underline = false },
  SpellLocal = { underline = false },

  Visual = { bold = false, bg = colors.surface1 },

  LspReferenceText = { link = "MyDocumentHighlight" },
  LspReferenceRead = { link = "MyDocumentHighlight" },
  LspReferenceWrite = { link = "MyDocumentHighlight" },

  -- Remove the background of all floating windows
  NormalFloat = { bg = "none" },

  -- nvim-treesitter-context plugin
  TreesitterContextBottom = { bold = false, italic = false },
  TreesitterContext = { bg = "#373948" },
  TreesitterContextLineNumber = { bg = "#373948" },

  -- Custom highlight groups
  YankSystemHighlight = {
    fg = colors.base,
    bg = colors.yellow,
  },

  YankRegisterHighlight = {
    fg = colors.base,
    bg = colors.blue,
  },

  BufferLineBuffer = {
    bg = colors.base,
  },

  -- yanky.nvim
  YankyPut = { link = "YankRegisterHighlight" },
  -- we use aucmds to dynamically switch hl colors instead
  -- YankyYanked = { link = "YankRegisterHighlight" },

  MyDocumentHighlight = { bg = "#373948" }, --#3b3d4d
  BufferLineOffsetText = { bold = true, bg = colors.mantle },

  Cursor = { reverse = true },

  -- NeoTreeWinSeparator = { bg = colors.mantle, fg = colors.mantle },
}

return {
  setup = function()
    for group, style in pairs(custom_highlights) do
      Util.hl(group, style)
    end

    vim.api.nvim_set_option_value("guicursor", "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkon1", {
      scope = "global",
    })
  end,
}
