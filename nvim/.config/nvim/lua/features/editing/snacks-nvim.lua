--- @module 'snacks.bufdelete'
local bufdelete = Defer.on_exported_call('snacks.bufdelete')
--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')
--- @module 'snacks.scratch'
local scratch = Defer.on_exported_call('snacks.scratch')

return {
  'snacks.nvim',
  keys = {
    { '<A-w>', bufdelete.delete, mode = { 'i', 'x', 'n', 's' }, desc = 'Close Buffer' },
    {
      -- Cmd+Shift+W, sent by the rex config; inspect with :echo keytrans(getcharstr())
      '<D-S-w>',
      function()
        Snacks.bufdelete.other()
        Notifier.info('Closed Other Buffers', { title = 'Buffers' })
      end,
      mode = { 'i', 'x', 'n', 's' },
      desc = 'Close Other Buffers',
    },
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
      scratch = UI.layout.float_fn('lg'),
    },
  },
}
