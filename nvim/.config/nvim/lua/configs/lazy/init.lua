local lazy_utils = require('configs.lazy.utils')
lazy_utils.ensure_lazy()

-- LazyFile events for reference:
-- { 'BufReadPost', 'BufNewFile', 'BufWritePre' }

-- [[ Configure and install plugins ]]
local lg = require('configs.size').popup.lg
require('lazy').setup({
  version = '*',
  ui = {
    size = { width = lg.width, height = lg.height },
    border = 'rounded',
    backdrop = 100,
    title = ' Lazy ',
  },
  spec = {
    { import = 'plugins.ui' }, -- Must be first for require('utils.ui').catppuccin to work correctly
    { import = 'plugins.ai' },
    { import = 'plugins.coding' },
    { import = 'plugins.editor' },
    { import = 'plugins.formatting' },
    { import = 'plugins.lsp' },
    { import = 'plugins.treesitter' },
  },
  checker = { enabled = false, notify = false },
  defaults = {
    lazy = true, -- Don't eaglerly load plugins by default
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
      },
    },
  },
})
