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

    local opts = {
      transparent_background = true,
      -- Skip the startup scan of every installed plugin; the integrations below are explicit
      auto_integrations = false,

      custom_highlights = {
        -- Native context menu
        Pmenu = { bg = 'none', fg = palette.text },
        PmenuSel = { bg = palette.surface0, style = {} },

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
        underlines = {
          errors = { 'undercurl' },
          hints = { 'undercurl' },
          warnings = { 'undercurl' },
          information = { 'undercurl' },
          ok = { 'undercurl' },
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
        blink_cmp = true,
        dropbar = true, -- color_mode = false comes from catppuccin's defaults
        flash = true,
        harpoon = true,
        ufo = true,
      },
    }

    -- Merged in rather than written above because the lazygit codediff renderer
    -- loads the same module headlessly: these four decide what a highlighted
    -- diff row looks like, and a second copy here is what would let the two
    -- drift apart. See the module's own header.
    local treesitter_highlights = require('config.treesitter-highlights')
    for group, hl in pairs(treesitter_highlights(palette)) do
      opts.custom_highlights[group] = hl
    end

    return opts
  end,

  config = function(_, opts)
    local catppuccin = require('catppuccin')
    catppuccin.setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
