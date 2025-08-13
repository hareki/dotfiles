return {
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
      timer = require('configs.common').PUT_HL_TIMER,
    },
    system_clipboard = {
      sync_with_ring = false,
      clipboard_register = nil,
    },
  },
  keys = {
    { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text' },
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put text after cursor' },
    {
      'p',
      '"_d<Plug>(YankyPutBefore)',
      mode = { 'x' },
      desc = 'Put yanked text after cursor without overwriting register',
    },

    {
      'P',
      '"0<Plug>(YankyPutBefore)',
      mode = { 'n' },
      desc = 'Put yanked text after cursor without overwriting register',
    },
    {
      'P',
      '"_d"0<Plug>(YankyPutBefore)',
      mode = { 'x' },
      desc = 'Put yanked text after cursor without overwriting register',
    },

    {
      '<S-Up>',
      '<Plug>(YankyPreviousEntry)',
      desc = 'Select previous entry through yank history',
    },
    {
      '<S-Down>',
      '<Plug>(YankyNextEntry)',
      desc = 'Select next entry through yank history',
    },
  },
}
