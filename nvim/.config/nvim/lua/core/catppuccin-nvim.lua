return {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = Conf.priority.CORE, -- Should be loaded first to register the colorscheme correctly
  opts = function()
    local palette = UI.catppuccin.get_palette()
    local color = UI.catppuccin.get_palette('ext')

    local substitute_fg = palette.red
    local substitute_bg = UI.color.blend_hex(palette.mantle, substitute_fg)

    return {
      transparent_background = true,
      default_integrations = false,

      custom_highlights = {
        -- Native context menu
        Pmenu = { bg = 'none', fg = palette.text },
        PmenuSel = { bg = palette.surface0, style = {} },
        PmenuBorder = { bg = 'none', fg = palette.blue },

        Substitute = { bg = substitute_bg, fg = substitute_fg },
        WinSeparator = { fg = palette.overlay0 },
        Visual = { bg = color.surface15, style = {} },
        DocumentHighlight = { bg = palette.surface0 },

        DiagnosticUnderlineInfo = { link = 'LspDiagnosticsUnderlineInformation' },
        DiagnosticUnderlineHint = { link = 'LspDiagnosticsUnderlineHint' },
        DiagnosticUnderlineWarn = { link = 'LspDiagnosticsUnderlineWarning' },
        DiagnosticUnderlineError = { link = 'LspDiagnosticsUnderlineError' },

        LspDiagnosticsUnderlineInformation = { sp = palette.sky },
        LspDiagnosticsUnderlineHint = { sp = palette.teal },
        LspDiagnosticsUnderlineWarning = { sp = palette.yellow },
        LspDiagnosticsUnderlineError = { sp = palette.red },

        LspReferenceText = { link = 'DocumentHighlight' },
        LspReferenceRead = { link = 'DocumentHighlight' },
        LspReferenceWrite = { link = 'DocumentHighlight' },

        NormalFloat = { bg = 'none' },
        FloatBorder = { bg = 'none', fg = palette.blue },
        FloatTitle = { bg = 'none', fg = palette.blue, bold = true },

        LineNr = { fg = palette.overlay0 },
        CursorLineNr = { fg = palette.blue },

        TabLine = {
          bg = 'none',
          fg = palette.surface1,
        },
        TabLineFill = {
          bg = 'none',
        },

        ['@string.special.path'] = { fg = palette.text },
        ['@markup.quote'] = { fg = palette.text },
        ['@markup.italic'] = { fg = palette.flamingo, italic = true },
        ['@markup.strong'] = { fg = palette.flamingo, bold = true },

        ModifiedIndicator = { fg = palette.yellow },
        SnippetTabStop = { bg = color.snippet_tab_stop },

        LazyH1 = { bg = palette.blue, fg = palette.base },
        LazyDir = { fg = palette.blue },
        LazyUrl = { fg = palette.blue },
        LazyReasonStart = { fg = palette.blue },
        LazySpecial = { fg = palette.blue },
        LazyProgressDone = { fg = palette.blue },

        -- Custom highlight group, shared across dropbar.nvim, snacks.nvim and nvim-telescope
        ListCursorLine = { bg = palette.surface0 },

        ErrorMsg = { fg = palette.text, style = {} },
        WarningMsg = { fg = palette.text, style = {} },
      },
      lsp_styles = {
        virtual_text = {
          errors = { 'italic' },
          hints = { 'italic' },
          warnings = { 'italic' },
          information = { 'italic' },
          ok = { 'italic' },
        },
        underlines = {
          errors = { 'undercurl' },
          hints = { 'undercurl' },
          warnings = { 'undercurl' },
          information = { 'undercurl' },
          ok = { 'undercurl' },
        },
        inlay_hints = {
          background = true,
        },
      },
      integrations = {
        nvimtree = true,
        grug_far = true,
        gitsigns = true,
        rainbow_delimiters = true,
        lsp_trouble = true,
        render_markdown = true,
        mini = true,
        noice = true,
        notify = true,
        snacks = true,
        telescope = true,
        which_key = true,
        blink_cmp = {
          enabled = true,
          style = 'bordered',
        },
      },
    }
  end,

  config = function(_, opts)
    local catppuccin = require('catppuccin')
    catppuccin.setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
