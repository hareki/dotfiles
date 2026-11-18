-- Neovim's own diagnostics: how they display, and the jumps between them
return {
  'vim-diagnostic',
  virtual = true,
  event = 'VeryLazy',
  config = function()
    local utils = require('features.diagnostics.vim-diagnostic.utils')
    utils.setup()
  end,
}
