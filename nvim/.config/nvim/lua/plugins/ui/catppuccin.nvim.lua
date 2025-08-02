return {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = 1000, -- Should be loaded first to register the colorscheme correctly
  opts = {
    default_integrations = false,
    integrations = {
      cmp = true,
      dashboard = true,
      nvimtree = true,
      flash = true,
      fzf = true,
      grug_far = true,
      gitsigns = true,
      rainbow_delimiters = true,
      lsp_trouble = true,
      markdown = true,
      mini = true,
      noice = true,
      notify = true,
      snacks = true,
      telescope = true,
      treesitter = true,
      treesitter_context = true,
      which_key = true,
      native_lsp = {
        enabled = true,
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
      indent_blankline = {
        enabled = true,
      },
      blink_cmp = {
        enabled = true,
        style = 'bordered',
      },
    },
  },
  config = function(_, opts)
    require('catppuccin').setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')

    local palette = require('utils.ui').get_palette()

    -- Most of these are not declared in the official catppuccin nvim highlights, so `opts.highlight_overrides` won't work.
    require('utils.ui').set_highlights({
      WinSeparator = { fg = palette.blue },
      Visual = { bold = false, bg = palette.surface1 },
      DocumentHighlight = { bg = '#373948' },

      DiagnosticUnderlineInfo = { link = 'LspDiagnosticsUnderlineInformation' },
      DiagnosticUnderlineHint = { link = 'LspDiagnosticsUnderlineHint' },
      DiagnosticUnderlineWarn = { link = 'LspDiagnosticsUnderlineWarning' },
      DiagnosticUnderlineError = { link = 'LspDiagnosticsUnderlineError' },

      LspDiagnosticsUnderlineInformation = { undercurl = true, sp = palette.sky },
      LspDiagnosticsUnderlineHint = { undercurl = true, sp = palette.teal },
      LspDiagnosticsUnderlineWarning = { undercurl = true, sp = palette.yellow },
      LspDiagnosticsUnderlineError = { undercurl = true, sp = palette.red },

      -- Remove the undercurl but keep spell checker on to use cmp-spell
      SpellBad = { underline = false },
      SpellCap = { underline = false },
      SpellRare = { underline = false },
      SpellLocal = { underline = false },

      LspReferenceText = { link = 'DocumentHighlight' },
      LspReferenceRead = { link = 'DocumentHighlight' },
      LspReferenceWrite = { link = 'DocumentHighlight' },

      NormalFloat = { bg = 'none' },
      FloatBorder = { bg = palette.base, fg = palette.blue },
      FloatTitle = { fg = palette.blue },

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
