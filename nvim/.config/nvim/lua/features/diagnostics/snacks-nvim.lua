--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')

return {
  'snacks.nvim',
  keys = {
    { '<leader>fd', picker.diagnostics_buffer, desc = 'Find Diagnostics Buffer' },
    { '<leader>fD', picker.diagnostics, desc = 'Find Diagnostics' },
  },
}
