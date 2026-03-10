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
    lazy = false,
    config = function()
      local mc = require('multicursor-nvim')
      mc.setup({
        ---@diagnostic disable-next-line: assign-type-mismatch wrong type, `false` to disable signs
        signs = false,
      })

      --- @param lhr string
      --- @param callback fun(): nil
      --- @param desc string
      local function set(lhr, callback, desc)
        vim.keymap.set({ 'n', 'x' }, lhr, callback, { desc = desc })
      end

      -- Add or skip adding a new cursor by matching word/selection
      set('<leader>mn', function()
        mc.matchAddCursor(1)
      end, 'Multicursor: Add Next Match Cursor')

      set('<leader>ms', function()
        mc.matchSkipCursor(1)
      end, 'Multicursor: Skip Next Match Cursor')

      set('<leader>mN', function()
        mc.matchAddCursor(-1)
      end, 'Multicursor: Add Previous Match Cursor')

      set('<leader>mS', function()
        mc.matchSkipCursor(-1)
      end, 'Multicursor: Skip Previous Match Cursor')

      -- Remapped from <C-m> in ghostty configs, for whatever reason
      -- <C-m> is recognized as <CR> by Neovim by default
      set('<F37>', mc.toggleCursor, 'Multicursor: Toggle Cursor')

      mc.addKeymapLayer(function(layerSet)
        -- Delete the main cursor.
        layerSet({ 'n', 'x' }, '<leader>mx', mc.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet('n', '<esc>', function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)
    end,
  },
}
