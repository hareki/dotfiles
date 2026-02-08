return {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = Priority.CORE, -- Should be loaded first to register the colorscheme correctly
  opts = function()
    local utils = require('utils.ui')
    local palette = utils.get_palette()
    local color = require('config.palette_ext')

    local substitute_fg = palette.red
    local substitute_bg = utils.blend_hex(palette.mantle, substitute_fg)

    return {
      transparent_background = true,
      default_integrations = false,

      custom_highlights = {
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

        ModifiedIndicator = { fg = palette.yellow },
        SnippetTabStop = { bg = color.blue1 },
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
        which_key = true,
        mason = true,
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
    local catppuccin = require('catppuccin')
    catppuccin.setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
