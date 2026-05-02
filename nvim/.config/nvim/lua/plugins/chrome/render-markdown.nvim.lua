local md_filetypes = { 'markdown' }

return {
  Catppuccin(function(palette)
    return {
      RenderMarkdownCode = { bg = palette.base },
    }
  end),

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = md_filetypes,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    opts = function()
      ---@module 'render-markdown'
      ---@type render.md.UserConfig
      return {
        file_types = md_filetypes,
        sign = {
          enabled = false,
        },
        callout = {
          error = {
            rendered = Icons.diagnostics.Error .. 'Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = Icons.misc.quote_bar, -- Thinner line for quotes
        },
      }
    end,
  },
}
