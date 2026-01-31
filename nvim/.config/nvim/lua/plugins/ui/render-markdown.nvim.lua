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
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons', '3rd/image.nvim' },

    opts = function()
      ---@module 'render-markdown'
      ---@type render.md.UserConfig
      return {
        file_types = md_filetypes,
        callout = {
          error = {
            rendered = ' Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = '▌', -- Thinner line for quotes
        },
      }
    end,
  },
}
