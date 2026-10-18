return {
  'snacks.nvim',
  keys = {
    {
      '<leader>fd',
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = 'Find Diagnostics Buffer',
    },
    {
      '<leader>fD',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = 'Find Diagnostics',
    },
  },
}
