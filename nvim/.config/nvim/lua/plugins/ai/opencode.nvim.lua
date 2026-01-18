return {
  'NickvanDyke/opencode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  keys = function()
    return {
      {
        '<A-a>',
        function()
          require('opencode').toggle()
        end,
        mode = { 'n', 't' },
        desc = 'Toggle Opencode',
      },
      {
        '<leader>aa',
        function()
          require('opencode').ask('@this: ', { submit = true })
        end,
        mode = { 'n', 'x' },
        desc = 'Ask Opencode',
      },
      {
        '<leader>ap',
        function()
          require('opencode').select()
        end,
        mode = { 'n', 'x' },
        desc = 'Select Opencode Prompt',
      },
      {
        '<leader>ar',
        function()
          return require('opencode').operator('@this ')
        end,
        mode = { 'n', 'x' },
        desc = 'Add Range to Opencode',
        expr = true,
      },
    }
  end,
  opts = function()
    local size = require('configs.size').side_panel.lg
    ---@type opencode.Opts
    return {
      provider = {
        enabled = 'snacks',
        ---@type opencode.provider.snacks.Opts
        snacks = {
          win = {
            width = size.width,
          },
        },
      },
    }
  end,
  config = function(_, opts)
    vim.g.opencode_opts = opts
  end,
}
