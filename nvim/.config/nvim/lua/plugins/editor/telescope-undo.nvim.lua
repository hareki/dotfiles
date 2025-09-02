return {
  'debugloop/telescope-undo.nvim',
  dependencies = {
    {
      'nvim-telescope/telescope.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
    },
  },
  keys = {
    {
      '<leader>fu',
      '<cmd>Telescope undo<cr>',
      desc = 'Open Undo History',
    },
  },
  config = function()
    require('telescope').load_extension('undo')
  end,
}
