local prefix = 'Flash: '

return {
  WhichKey({
    rules = { plugin = 'flash.nvim', icon = Icons.tools.flash, color = 'yellow' },
  }),
  Catppuccin(function(palette)
    return {
      FlashPromptIcon = { fg = palette.yellow },
    }
  end),

  {
    'folke/flash.nvim',
    keys = {
      {
        'f',
        mode = { 'n', 'x' },
      },
      {
        't',
        mode = { 'n', 'x' },
      },
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          local flash = require('flash')
          flash.jump()
        end,
        desc = prefix .. 'Jump',
      },
      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          local flash = require('flash')
          flash.treesitter()
        end,
        desc = prefix .. 'Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          local flash = require('flash')
          flash.remote()
        end,
        desc = prefix .. 'Remote',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          local flash = require('flash')
          flash.treesitter_search()
        end,
        desc = prefix .. 'Treesitter Search',
      },
      -- Simulate nvim-treesitter incremental selection
      {
        '<C-Space>',
        mode = { 'n', 'o', 'x' },
        function()
          local flash = require('flash')
          flash.treesitter({
            actions = {
              ['<C-Space>'] = 'next',
              ['<BS>'] = 'prev',
            },
          })
        end,
        desc = prefix .. 'Treesitter Incremental Selection',
      },
    },
    --- @type Flash.Config
    opts = {
      prompt = {
        prefix = { { Icons.tools.flash .. ' Flash', 'FlashPromptIcon' } },
      },
    },
  },
}
