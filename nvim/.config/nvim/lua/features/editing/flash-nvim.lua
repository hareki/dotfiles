local prefix = 'Flash: '

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
        desc = prefix .. 'Find Char',
      },
      {
        't',
        mode = { 'n', 'x' },
        desc = prefix .. 'Till Char',
      },
      {
        'F',
        mode = { 'n', 'x' },
        desc = prefix .. 'Find Char Backwards',
      },
      {
        'T',
        mode = { 'n', 'x' },
        desc = prefix .. 'Till Char Backwards',
      },
      {
        ';',
        mode = { 'n', 'x' },
        desc = prefix .. 'Repeat Char Motion',
      },
      {
        ',',
        mode = { 'n', 'x' },
        desc = prefix .. 'Repeat Char Motion Reversed',
      },
      { 's', flash.jump, mode = { 'n', 'x', 'o' }, desc = prefix .. 'Jump' },
      { 'S', flash.treesitter, mode = { 'n', 'o', 'x' }, desc = prefix .. 'Treesitter' },
      { 'r', flash.remote, mode = 'o', desc = prefix .. 'Remote' },
      {
        'R',
        flash.treesitter_search,
        mode = { 'o', 'x' },
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
          prefix = { { Conf.icons.tools.FLASH .. ' Flash ', 'FlashPromptIcon' } },
        },
      }
    end,
  },
}
