return {
  'snacks.nvim',
  keys = {
    {
      '<leader>fR',
      function()
        Snacks.picker.registers()
      end,
      desc = "Find Registers' Contents",
    },
    {
      '<leader>fu',
      function()
        Snacks.picker.undo()
      end,
      desc = 'Open Undo History',
    },
    {
      '<leader>.',
      function()
        Snacks.scratch()
      end,
      desc = 'Toggle Scratch Buffer',
    },
    {
      '<leader>f.',
      function()
        Snacks.scratch.select()
      end,
      desc = 'Select Scratch Buffer',
    },
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
