return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 100, -- The docs recommend loading this plugin early
  keys = {
    {
      '<leader>g',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit',
    },
  },
  opts = function()
    local popup_config = require('utils.size').popup_config
    local input_config = popup_config('input')
    local lg_float_config = popup_config('lg')

    return {
      words = {
        enabled = true,
      },
      bigfile = {
        enabled = true,
      },
      input = {
        enabled = true,
      },
      lazygit = {
        enabled = true,
        configure = false,
      },
      styles = {
        input = {
          height = input_config.height,
          width = input_config.width,
          col = input_config.col,
          row = input_config.row,
        },
        lazygit = {
          backdrop = false,
          border = 'rounded',
          title = ' Lazygit ',
          title_pos = 'center',

          height = lg_float_config.height,
          width = lg_float_config.width,
          col = lg_float_config.col,
          row = lg_float_config.row,
        },
      },
    }
  end,
}
