return {
  UI.catppuccin(function(_)
    return {
      RenderMarkdownCode = { bg = 'none' },
    }
  end),

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = Conf.Filetypes.MARKDOWN,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    opts = function()
      --- @module 'render-markdown'
      --- @type render.md.UserConfig
      return {
        file_types = Conf.Filetypes.MARKDOWN,
        sign = {
          enabled = false,
        },
        callout = {
          error = {
            rendered = Conf.Icons.diagnostics.ERROR .. 'Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = Conf.Icons.misc.QUOTE_BAR, -- Thinner line for quotes
        },
      }
    end,
  },
}
