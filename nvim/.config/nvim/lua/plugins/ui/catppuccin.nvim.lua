return {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = 1000, -- Should be loaded first to register the colorscheme correctly
  opts = function()
    local get_palette = require('catppuccin.palettes').get_palette
    local palette = get_palette()

    return {
      transparent_background = true,
      default_integrations = false,
      custom_highlights = {
        WinSeparator = { fg = palette.overlay0 },
        Visual = { bg = '#4f5164', style = {} }, -- Darkened version of surface2
        DocumentHighlight = { bg = palette.surface0 },

        DiagnosticUnderlineInfo = { link = 'LspDiagnosticsUnderlineInformation' },
        DiagnosticUnderlineHint = { link = 'LspDiagnosticsUnderlineHint' },
        DiagnosticUnderlineWarn = { link = 'LspDiagnosticsUnderlineWarning' },
        DiagnosticUnderlineError = { link = 'LspDiagnosticsUnderlineError' },

        LspDiagnosticsUnderlineInformation = { sp = palette.sky },
        LspDiagnosticsUnderlineHint = { sp = palette.teal },
        LspDiagnosticsUnderlineWarning = { sp = palette.yellow },
        LspDiagnosticsUnderlineError = { sp = palette.red },

        -- Remove the undercurl but keep spell checker on to use cmp-spell
        SpellBad = { style = {} },
        SpellCap = { style = {} },
        SpellRare = { style = {} },
        SpellLocal = { style = {} },

        LspReferenceText = { link = 'DocumentHighlight' },
        LspReferenceRead = { link = 'DocumentHighlight' },
        LspReferenceWrite = { link = 'DocumentHighlight' },

        NormalFloat = { bg = 'none' },
        FloatBorder = { bg = palette.base, fg = palette.blue },
        FloatTitle = { bg = palette.base, fg = palette.blue },

        LineNr = { fg = palette.overlay0 },
        CursorLineNr = { fg = palette.blue },

        TabLine = {
          bg = palette.base,
          fg = palette.surface1,
        },
        TabLineFill = {
          bg = palette.base,
        },

        ['@string.special.path'] = { fg = palette.text },
        ['@markup.quote'] = { fg = palette.text },
        ['@markup.italic'] = { fg = palette.flamingo, italic = true },
        ['@markup.strong'] = { fg = palette.flamingo, bold = true },
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
        cmp = true,
        dashboard = true,
        nvimtree = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        diffview = true,
        rainbow_delimiters = true,
        lsp_trouble = true,
        markdown = true,
        render_markdown = true,
        mini = true,
        noice = true,
        notify = true,
        snacks = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
        dropbar = {
          enabled = true,
          color_mode = false, -- enable color for kind's texts, not just kind's icons
        },
        indent_blankline = {
          enabled = true,
        },
        blink_cmp = {
          enabled = true,
          style = 'bordered',
        },
      },
    }
  end,
  config = function(_, opts)
    require('catppuccin').setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
