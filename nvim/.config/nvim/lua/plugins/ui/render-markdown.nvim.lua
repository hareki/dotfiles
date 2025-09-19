return {
  require('utils.ui').catppuccin(function(palette)
    return {
      RenderMarkdownCode = { bg = palette.base },
    }
  end),
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = function()
      return {
        file_types = { 'markdown' },
        completions = { blink = { enabled = true } },
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
