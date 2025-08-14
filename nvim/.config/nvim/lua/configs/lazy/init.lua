local LazyUtils = require('configs.lazy.utils')

LazyUtils.ensure_lazy()
LazyUtils.register_events()

-- [[ Configure and install plugins ]]
local lg = require('configs.size').popup.lg
require('lazy').setup({
  version = '*',
  ui = {
    size = { width = lg.WIDTH, height = lg.HEIGHT },
    border = 'rounded',
    backdrop = 100,
    title = ' Lazy ',
  },
  spec = {
    { import = 'plugins.ai' },
    { import = 'plugins.coding' },
    { import = 'plugins.editor' },
    { import = 'plugins.formatting' },
    { import = 'plugins.linting' },
    { import = 'plugins.lsp' },
    { import = 'plugins.treesitter' },
    { import = 'plugins.ui' },
  },
  checker = { enabled = false, notify = false },
  defaults = {
    lazy = true,
    version = false, -- Always use the latest git commit
  },
  performance = {
    rtp = {
      -- https://github.com/mrjones2014/dotfiles/blob/2a120037b2c7d7d9bf27b03088e7e91360a8f332/nvim/lua/my/plugins.lua#L14
      disabled_plugins = {
        'netrw',
        'netrwPlugin',
        'netrwSettings',
        'netrwFileHandlers',
        'gzip',
        'zip',
        'zipPlugin',
        'tar',
        'matchparen',
        'tarPlugin',
        'getscript',
        'getscriptPlugin',
        'vimball',
        'vimballPlugin',
        'tohtml',
        'logipat',
        'tutor',
        'zipPlugin',
      },
    },
  },
})
