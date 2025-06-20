local palette = require("catppuccin.palettes").get_palette("mocha")

Util.highlights({
    Visual = { bold = false, bg = palette.surface1 },
    DocumentHighlight = { bg = "#373948" }, --#3b3d4d

    DiagnosticUnderlineInfo = { link = "LspDiagnosticsUnderlineInformation" },
    DiagnosticUnderlineHint = { link = "LspDiagnosticsUnderlineHint" },
    DiagnosticUnderlineWarn = { link = "LspDiagnosticsUnderlineWarning" },
    DiagnosticUnderlineError = { link = "LspDiagnosticsUnderlineError" },

    LspDiagnosticsUnderlineInformation = { undercurl = true, sp = palette.sky },
    LspDiagnosticsUnderlineHint = { undercurl = true, sp = palette.teal },
    LspDiagnosticsUnderlineWarning = { undercurl = true, sp = palette.yellow },
    LspDiagnosticsUnderlineError = { undercurl = true, sp = palette.red },

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

    TabLine = {
        bg = palette.base,
        fg = palette.surface1,
    },
    TabLineFill = {
        bg = palette.base,
    },
})
