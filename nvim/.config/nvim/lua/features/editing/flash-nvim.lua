local PREFIX = 'Flash: '

--- @module 'flash'
local flash = Defer.on_exported_call('flash')

return {
  UI.catppuccin(function(palette)
    return {
      FlashLabel = { fg = palette.red },
      FlashMatch = { fg = palette.blue },
      FlashCurrent = { fg = palette.yellow },
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
        desc = PREFIX .. 'Find Char',
      },
      {
        't',
        mode = { 'n', 'x' },
        desc = PREFIX .. 'Till Char',
      },
      {
        'F',
        mode = { 'n', 'x' },
        desc = PREFIX .. 'Find Char Backwards',
      },
      {
        'T',
        mode = { 'n', 'x' },
        desc = PREFIX .. 'Till Char Backwards',
      },
      {
        ';',
        mode = { 'n', 'x' },
        desc = PREFIX .. 'Repeat Char Motion',
      },
      {
        ',',
        mode = { 'n', 'x' },
        desc = PREFIX .. 'Repeat Char Motion Reversed',
      },
      { 's', flash.jump, mode = { 'n', 'x', 'o' }, desc = PREFIX .. 'Jump' },
      { 'S', flash.treesitter, mode = { 'n', 'o', 'x' }, desc = PREFIX .. 'Treesitter' },
      { 'r', flash.remote, mode = 'o', desc = PREFIX .. 'Remote' },
      {
        'R',
        flash.treesitter_search,
        mode = { 'o', 'x' },
        desc = PREFIX .. 'Treesitter Search',
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
        desc = PREFIX .. 'Treesitter Incremental Selection',
      },
    },
    opts = function()
      --- @type Flash.Config
      return {
        prompt = {
          prefix = { { ' ' }, { Conf.icons.tools.FLASH .. ' Flash ', 'FlashPromptIcon' } },
        },
      }
    end,
  },
}
