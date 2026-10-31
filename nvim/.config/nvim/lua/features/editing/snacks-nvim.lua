--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')
--- @module 'snacks.scratch'
local scratch = Defer.on_exported_call('snacks.scratch')

return {
  'snacks.nvim',
  keys = {
    { '<leader>fR', picker.registers, desc = "Find Registers' Contents" },
    { '<leader>fu', picker.undo, desc = 'Open Undo History' },
    { '<leader>.', scratch.open, desc = 'Toggle Scratch Buffer' },
    { '<leader>f.', scratch.select, desc = 'Select Scratch Buffer' },
  },

  opts = {
    scratch = { enabled = true },

    picker = {
      sources = {
        scratch = {
          win = {
            input = {
              keys = {
                ['x'] = { 'scratch_delete' },
              },
            },
          },
        },
      },
    },

    styles = {
      scratch = UI.layout.popup_fn('lg'),
    },
  },
}
