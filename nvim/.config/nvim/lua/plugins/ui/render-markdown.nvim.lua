return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = function()
    return {
      completions = { blink = { enabled = true } },
      callout = {
        error = {
          rendered = ' Error',
        },
      },
    }
  end,
}
