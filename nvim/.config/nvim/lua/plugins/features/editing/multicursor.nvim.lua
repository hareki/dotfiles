local mc = Defer.on_exported_call('multicursor-nvim')

return {
  WhichKey({
    specs = {
      { '<leader>m', group = 'Multicursor', mode = { 'n', 'x' } },
    },

    rules = { pattern = 'multicursor', icon = Icons.tools.multicursor, color = 'blue' },
  }),
  Catppuccin(function(palette)
    local utils = require('utils.ui')
    local enabled_fg = palette.green
    local disabled_fg = palette.red
    local enabled_bg = utils.blend_hex(palette.mantle, enabled_fg)
    local disabled_bg = utils.blend_hex(palette.mantle, disabled_fg)

    return {
      MultiCursorCursor = { bg = enabled_bg, fg = enabled_fg },
      MultiCursorDisabledCursor = { bg = disabled_bg, fg = disabled_fg },
    }
  end),
  {
    'jake-stewart/multicursor.nvim',
    keys = {
      {
        '<C-n>',
        function()
          mc.matchAddCursor(1)
        end,
        desc = 'Multicursor: Add Next Match Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-S-n>',
        function()
          mc.matchSkipCursor(1)
        end,
        desc = 'Multicursor: Skip Next Match Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-p>',
        function()
          mc.matchAddCursor(-1)
        end,
        desc = 'Multicursor: Add Previous Match Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-S-p>',
        function()
          mc.matchSkipCursor(-1)
        end,
        desc = 'Multicursor: Skip Previous Match Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-Up>',
        function()
          mc.lineAddCursor(-1)
        end,
        desc = 'Multicursor: Add Previous Line Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-Down>',
        function()
          mc.lineAddCursor(1)
        end,
        desc = 'Multicursor: Add Next Line Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-Left>',
        function()
          mc.lineSkipCursor(-1)
        end,
        desc = 'Multicursor: Skip Previous Line Cursor',
        mode = { 'n', 'x' },
      },
      {
        '<C-Right>',
        function()
          mc.lineSkipCursor(1)
        end,
        desc = 'Multicursor: Skip Next Line Cursor',
        mode = { 'n', 'x' },
      },
      -- Remapped from <C-m> in ghostty configs, for whatever reason
      -- <C-m> is recognized as <CR> by Neovim by default
      { '<F37>', mc.toggleCursor, desc = 'Multicursor: Toggle Cursor', mode = { 'n', 'x' } },
    },
    opts = {
      { signs = false },
    },
    config = function(_, opts)
      local multicursor = require('multicursor-nvim')
      multicursor.setup(opts)

      multicursor.addKeymapLayer(function(layerSet)
        -- Delete the main cursor.
        layerSet({ 'n', 'x' }, '<leader>mx', multicursor.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet('n', '<esc>', function()
          if not multicursor.cursorsEnabled() then
            multicursor.enableCursors()
          else
            multicursor.clearCursors()
          end
        end)
      end)
    end,
  },
}
