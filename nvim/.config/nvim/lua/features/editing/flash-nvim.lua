local prefix = 'Flash: '

--- @module 'flash'
local flash = Defer.on_exported_call('flash')

return {
  UI.catppuccin(function(palette)
    return {
      FlashPromptIcon = { fg = palette.yellow },
    }
  end, 'flash.nvim'),
  UI.which_key({
    rules = { plugin = 'flash.nvim', icon = Conf.icons.tools.FLASH, color = 'yellow' },
  }),

  {
    'folke/flash.nvim',
    keys = {
      {
        'f',
        mode = { 'n', 'x' },
        desc = prefix .. 'Find Char',
      },
      {
        't',
        mode = { 'n', 'x' },
        desc = prefix .. 'Till Char',
      },
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          flash.jump()
        end,
        desc = prefix .. 'Jump',
      },
      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          flash.treesitter()
        end,
        desc = prefix .. 'Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          flash.remote()
        end,
        desc = prefix .. 'Remote',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          flash.treesitter_search()
        end,
        desc = prefix .. 'Treesitter Search',
      },
      -- Simulate nvim-treesitter incremental selection
      {
        '<C-Space>',
        mode = { 'n', 'o', 'x' },
        function()
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
    opts = function()
      --- @type Flash.Config
      return {
        prompt = {
          prefix = { { Conf.icons.tools.FLASH .. ' Flash', 'FlashPromptIcon' } },
        },
      }
    end,
  },
}
