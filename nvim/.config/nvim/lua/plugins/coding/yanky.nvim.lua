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
    event = 'VeryLazy',
    dependencies = {
      'kkharji/sqlite.lua',
      'hareki/snacks.nvim', -- Let yanky self register with snacks
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
        desc = 'Yank Text to End',
      },
      { 'h', '"+<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank Text to System Clipboard' },
      {
        'H',
        '"+<Plug>(YankyYank)$',
        desc = 'Yank to End to System Clipboard',
      },
      { 'p', '<Plug>(YankyPutAfter)', desc = 'Put Text' },
      { 'k', '"+<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put from System Clipboard' },
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
      -- Trimmed, No indent/trailing
      { 'yy', '^yg_', desc = 'Yank Line Trimmed' },
      { 'hh', '^"+yg_', desc = 'Yank Line Trimmed to System Clipboard' },
      {
        'dd',
        function()
          vim.cmd.normal({ args = { [[^dg_]] }, bang = true }) -- Delete from first nonblank to last nonblank
          vim.cmd.normal({ args = { [["_dd]] }, bang = true }) -- Remove remaining indent + newline (blackhole)
        end,
        desc = 'Delete Line Trimmed',
      },
    },
  },
}
