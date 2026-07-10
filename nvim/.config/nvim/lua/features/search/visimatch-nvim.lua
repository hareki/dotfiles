return {
  'wurli/visimatch.nvim',
  init = function()
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = vim.api.nvim_create_augroup('search.visimatch.lazy-load', { clear = true }),
      pattern = '*:[vV\22]*', -- v, V, <C-v> (\22 is the raw CTRL-V byte)
      desc = 'Load Visimatch in Visual Mode',
      once = true,
      callback = function()
        local lazy = require('lazy')
        lazy.load({ plugins = { 'visimatch.nvim' } })
      end,
    })
  end,

  opts = function()
    return {
      chars_lower_limit = 2,
      hl_group = 'DocumentHighlight',
    }
  end,
}
