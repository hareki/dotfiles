local lazy_utils = require('config.lazy.utils')
lazy_utils.ensure_lazy()

-- LazyFile events for reference:
-- { 'BufReadPost', 'BufNewFile', 'BufWritePre' }

-- [[ Configure and install plugins ]]
local size_configs = require('config.size')
local lg = size_configs.popup.lg
local lazy = require('lazy')
lazy.setup({
  version = '*',
  ui = {
    size = { width = lg.width, height = lg.height },
    border = 'rounded',
    backdrop = 100,
    title = ' Lazy ',
  },
  spec = {
    { import = 'plugins.core' },
    { import = 'plugins.core.lsp' },

    { import = 'plugins.chrome' },

    { import = 'plugins.features.navigation' },
    { import = 'plugins.features.completion' },
    { import = 'plugins.features.git' },
    { import = 'plugins.features.editing' },
    { import = 'plugins.features.search' },
    { import = 'plugins.features.diagnostics' },
    { import = 'plugins.features.formatting' },
    { import = 'plugins.features.ai' },
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
