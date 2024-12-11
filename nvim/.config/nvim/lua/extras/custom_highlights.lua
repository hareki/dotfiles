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

  LspReferenceText = { link = "DocumentHighlight" },
  LspReferenceRead = { link = "DocumentHighlight" },
  LspReferenceWrite = { link = "DocumentHighlight" },

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

  NeoTreeNormal = {
    bg = colors.base,
  },

  NeoTreeNormalNC = {
    bg = colors.base,
  },

  -- NeoTreeWinSeparator = { bg = colors.mantle, fg = colors.mantle },

  BufferLineBuffer = {
    bg = colors.base,
  },
  BufferLineOffsetText = { bold = true, bg = colors.mantle },

  TabLine = {
    bg = colors.base,
    fg = colors.surface1,
  },
  TabLineFill = {
    bg = colors.base,
  },

  YankyPut = { link = "YankRegisterHighlight" }, -- yanky.nvim

  DropBarKindDir = { link = "DropBarKindFile" },

  FloatTitle = { fg = colors.blue },

  -- We use aucmds to dynamically switch hl colors instead
  -- YankyYanked = { link = "YankRegisterHighlight" },

  -- Setting different color from "String" highlight group to avoid confusion
  RainbowDelimiterGreen = { fg = colors.rosewater },

  DocumentHighlight = { bg = "#373948" }, --#3b3d4d

  -- Highlight groups for vim-visual-multi: https://github.com/mg979/vim-visual-multi/blob/master/doc/vm-settings.txt
  VM_Extend = { link = "Visual" },
  VM_Cursor = { bg = colors.rosewater, fg = colors.base },
  VM_Mono = { link = "VM_Cursor" },
  VM_Highlight_Matches = { link = "DocumentHighlight" }, -- This is not official, just to unify the naming convention

  Cursor = { reverse = true },
}

return {
  setup = function()
    for group, style in pairs(custom_highlights) do
      Util.hl(group, style)
    end

    -- Can't set cursor shape for terminal mode, waiting for: https://github.com/neovim/neovim/issues/3681
    vim.api.nvim_set_option_value("guicursor", "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkon1", {
      scope = "global",
    })
  end,
}
