return {
  'echasnovski/mini.indentscope',
  version = false,
  event = 'LazyFile',
  opts = function()
    require('utils.ui').set_highlights({
      MiniIndentscopeSymbol = { fg = require('utils.ui').get_palette().blue },
    })
    return {
      -- symbol = "│",
      symbol = '┃',
      options = { try_as_border = true },
      draw = {
        delay = 100,
        -- animation = require('mini.indentscope').gen_animation.none()
      },
    }
  end,
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = {
        'Trouble',
        'alpha',
        'dashboard',
        'fzf',
        'help',
        'lazy',
        'mason',
        'neo-tree',
        'NvimTree',
        'notify',
        'snacks_notif',
        'snacks_terminal',
        'snacks_win',
        'toggleterm',
        'trouble',
        'dropbar_menu',
        'grug-far',
      },
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
    })
  end,
}
