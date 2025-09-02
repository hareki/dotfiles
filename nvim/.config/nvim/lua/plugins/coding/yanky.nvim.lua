return {
  require('utils.ui').catppuccin(function(palette)
    return {
      YankySystemYanked = {
        fg = palette.base,
        bg = palette.yellow,
      },
      YankySystemPut = {
        fg = palette.base,
        bg = palette.peach,
      },
      YankyRegisterYanked = {
        fg = palette.base,
        bg = palette.blue,
      },
      YankyRegisterPut = {
        fg = palette.base,
        bg = palette.teal,
      },
    }
  end),
  {
    'hareki/yanky.nvim',
    desc = 'Better Yank/Paste',
    event = 'LazyFile',
    dependencies = {
      { 'kkharji/sqlite.lua' },
    },
    opts = {
      ring = { storage = 'sqlite' },
      highlight = {
        on_yank = true,
        on_put = true,
        timer = 300,
      },
      system_clipboard = {
        sync_with_ring = false,
        clipboard_register = nil,
      },
    },
    keys = {
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank Text' },
      {
        'Y',
        '<Plug>(YankyYank)$',
        mode = 'n',
        desc = 'Yank Text to End',
      },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put Text' },
      -- Putting text in visual mode without overwriting the yank register
      {
        'p',
        '"_d<Plug>(YankyPutBefore)',
        mode = { 'x' },
        desc = 'Put Text',
      },
      {
        'P',
        '"_d"0<Plug>(YankyPutBefore)',
        mode = { 'x' },
        desc = 'Put Text from Register 0',
      },

      {
        'P',
        '"0<Plug>(YankyPutBefore)',
        mode = { 'n' },
        desc = 'Put Text from Register 0',
      },

      {
        '<S-Up>',
        '<Plug>(YankyPreviousEntry)',
        desc = 'Previous Yanky Entry',
      },
      {
        '<S-Down>',
        '<Plug>(YankyNextEntry)',
        desc = 'Next Yanky Entry',
      },
    },
  },
}
