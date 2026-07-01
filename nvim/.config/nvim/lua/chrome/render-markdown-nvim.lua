return {
  UI.catppuccin(function(palette)
    return {
      RenderMarkdownCode = { bg = palette.base },
    }
  end),

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = Conf.Filetypes.markdown,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    opts = function()
      --- @module 'render-markdown'
      --- @type render.md.UserConfig
      return {
        file_types = Conf.Filetypes.markdown,
        sign = {
          enabled = false,
        },
        callout = {
          error = {
            rendered = Conf.Icons.diagnostics.Error .. 'Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = Conf.Icons.misc.quote_bar, -- Thinner line for quotes
        },
      }
    end,
  },
}
