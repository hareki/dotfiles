return {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = 1000, -- Should be loaded first to register the colorscheme correctly
  opts = {
    default_integrations = false,
    custom_highlights = function(colors)
      ---@type palette
      local palette = colors

      return {
        WinSeparator = { fg = palette.blue },
        Visual = { bold = false, bg = '#4f5164' }, -- Darkened version of surface2
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

        TabLine = {
          bg = palette.base,
          fg = palette.surface1,
        },
        TabLineFill = {
          bg = palette.base,
        },

        ['@markup.quote'] = { fg = palette.text },
        ['@markup.italic'] = { fg = palette.flamingo, italic = true },
        ['@markup.strong'] = { fg = palette.flamingo, bold = true },

        -- MeanderingProgrammer/render-markdown.nvim
        RenderMarkdownCode = { bg = palette.base },

        -- hareki/grug-far.nvim
        GrugFarResultsMatch = { link = 'Search' },
        GrugFarPreview = { link = 'Search' },

        -- hareki/dashboard-nvim
        DashboardHeader = { fg = palette.blue },
        DashboardShortcut = { fg = palette.yellow },
        DashboardShortcut1 = { fg = palette.pink },
        DashboardShortcut2 = { fg = palette.yellow },
        DashboardShortcut3 = { fg = palette.green },
        DashboardShortcut4 = { fg = palette.mauve },
        DashboardShortcut5 = { fg = palette.red },
        DashboardProjectTitle = { fg = palette.blue },
        DashboardProjectIcon = { fg = palette.blue },
        DashboardMruTitle = { fg = palette.blue },
        DashboardFiles = { fg = palette.text },
        DashboardFooter = { fg = palette.rosewater, italic = true },

        -- hareki/yanky.nvim
        SystemYankHighlight = {
          fg = palette.base,
          bg = palette.yellow,
        },
        SystemPutHighlight = {
          fg = palette.base,
          bg = palette.peach,
        },

        RegisterYankHighlight = {
          fg = palette.base,
          bg = palette.blue,
        },
        RegisterPutHighlight = {
          fg = palette.base,
          bg = palette.teal,
        },

        -- nvim-treesitter/nvim-treesitter-context
        TreesitterContextBottom = { bold = false, italic = false },
        TreesitterContext = { link = 'DocumentHighlight' },
        TreesitterContextLineNumber = { link = 'DocumentHighlight' },

        -- echasnovski/mini.indentscope
        MiniIndentscopeSymbol = { fg = palette.blue },

        -- Bekaboo/dropbar.nvim
        DropBarKindDir = { link = 'DropBarKindFile' },

        -- hareki/trouble.nvim
        TroubleNormal = { link = 'NormalFloat' },
        TroublePreview = { link = 'Search' },

        -- nvim-tree/nvim-tree.lua
        NvimTreeSignColumn = {
          link = 'NormalFloat',
        },
        NvimTreeNormal = {
          link = 'Normal',
        },
        NvimTreeCutHL = {
          bg = palette.maroon,
          fg = palette.base,
        },
        NvimTreeCopiedHL = {
          bg = palette.surface2,
          fg = palette.text,
        },
      }
    end,
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
  end,
}
