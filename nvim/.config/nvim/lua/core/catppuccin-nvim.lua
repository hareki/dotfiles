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
      -- No startup plugin scan: each spec names its own with UI.catppuccin.integration()
      auto_integrations = false,

      custom_highlights = {
        -- Native context menu
        Pmenu = { bg = 'none', fg = palette.text },
        PmenuSel = { bg = palette.surface0, style = {} },

        Substitute = { bg = substitute_bg, fg = substitute_fg },
        WinSeparator = { fg = palette.overlay0 },
        Visual = { bg = color.surface15, style = {} },
        DocumentHighlight = { bg = palette.surface0 },

        LspReferenceText = { link = 'DocumentHighlight' },
        LspReferenceRead = { link = 'DocumentHighlight' },
        LspReferenceWrite = { link = 'DocumentHighlight' },

        NormalFloat = { bg = 'none' },
        FloatBorder = { bg = 'none', fg = palette.blue },
        FloatTitle = { bg = 'none', fg = palette.blue, bold = true },

        LineNr = { fg = palette.overlay0 },

        SnippetTabStop = { bg = color.snippet_tab_stop },

        -- Custom highlight group, shared across dropbar.nvim and snacks.nvim
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
    }

    -- Kept in their own module, which the lazygit codediff renderer also loads headlessly
    local treesitter_highlights = require('config.treesitter-highlights')
    opts.custom_highlights =
      vim.tbl_extend('error', opts.custom_highlights, treesitter_highlights(palette))

    return opts
  end,

  config = function(_, opts)
    local catppuccin = require('catppuccin')
    catppuccin.setup(opts)
    vim.cmd.colorscheme('catppuccin-mocha')
  end,
}
