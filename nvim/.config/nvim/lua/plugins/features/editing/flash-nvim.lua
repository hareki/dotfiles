return {
  WhichKey({
    rules = { plugin = 'flash.nvim', icon = Icons.tools.flash, color = 'yellow' },
  }),

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
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          local flash = require('flash')
          flash.treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          local flash = require('flash')
          flash.remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          local flash = require('flash')
          flash.treesitter_search()
        end,
        desc = 'Treesitter Search',
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
        desc = 'Treesitter Incremental Selection',
      },
    },
    ---@type Flash.Config
    opts = {},
  },
}
