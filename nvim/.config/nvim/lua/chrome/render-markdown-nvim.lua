return {
  UI.catppuccin(function(_)
    return {
      RenderMarkdownCode = { bg = 'none' },
    }
  end, 'render-markdown.nvim'),

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = Conf.filetypes.MARKDOWN,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    opts = function()
      --- @module 'render-markdown'
      --- @type render.md.UserConfig
      return {
        file_types = Conf.filetypes.MARKDOWN,
        sign = {
          enabled = false,
        },
        callout = {
          error = {
            rendered = Conf.icons.diagnostics.ERROR .. 'Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = Conf.icons.misc.QUOTE_BAR, -- Thinner line for quotes
        },
      }
    end,
  },
}
