local prefix = 'Flash: '

--- @module 'flash'
local flash = Defer.on_exported_call('flash')

return {
  UI.which_key({
    rules = { plugin = 'flash.nvim', icon = Conf.icons.tools.FLASH, color = 'yellow' },
  }),
  UI.catppuccin(function(palette)
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
    --- @type Flash.Config
    opts = {
      prompt = {
        prefix = { { Conf.icons.tools.FLASH .. ' Flash', 'FlashPromptIcon' } },
      },
    },
  },
}
