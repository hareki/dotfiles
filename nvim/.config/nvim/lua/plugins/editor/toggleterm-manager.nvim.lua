return {
  'hareki/toggleterm-manager.nvim',
  dependencies = {
    'akinsho/toggleterm.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim', -- only needed because it's a dependency of telescope
  },
  keys = {
    {
      '<leader>fz',
      function()
        local layout_config = require('utils.ui').telescope_layout
        require('toggleterm-manager').open({
          layout_config = {
            vertical = layout_config('md'),
          },
        })
      end,
      desc = 'Find Terminals',
    },
  },
  opts = function()
    local actions = require('lib.actions')

    return {
      mappings = { -- key mappings bound inside the telescope window
        i = {
          ['<CR>'] = { action = actions.open_term, exit_on_action = true },
          ['<C-i>'] = false,
        },
        n = {
          ['<CR>'] = { action = actions.open_term, exit_on_action = true },
          ['x'] = { action = actions.delete_term, exit_on_action = false },
          ['r'] = { action = actions.rename_term, exit_on_action = false },
          ['n'] = { action = actions.create_and_name_term, exit_on_action = false },
        },
      },
      titles = {
        preview = require('configs.picker').telescope_preview_title,
        prompt = 'Terminals',
        results = false,
      },
      results = {
        fields = {
          'term_name', -- toggleterm's display_name if it exists, else the terminal's id assigned by toggleterm
        },
      },
    }
  end,
}
