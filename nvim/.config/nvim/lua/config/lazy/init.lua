local lazy_utils = require('config.lazy.utils')
lazy_utils.ensure_lazy()

-- LazyFile events for reference:
-- { 'BufReadPost', 'BufNewFile', 'BufWritePre' }

-- [[ Configure and install plugins ]]
local lg = Conf.Size.popup.lg
local lazy = require('lazy')
lazy.setup({
  version = '*',
  rocks = {
    enabled = false,
  },
  ui = {
    size = { width = lg.WIDTH, height = lg.HEIGHT },
    border = 'rounded',
    backdrop = 100,
    title = ' Plugin Manager ',
    icons = {
      loaded = Conf.Icons.misc.PACKAGE_ACTIVE,
      not_loaded = Conf.Icons.misc.PACKAGE_INACTIVE,
    },
  },
  spec = {
    { import = 'core' },
    { import = 'core.lsp' },

    { import = 'chrome' },

    { import = 'features.navigation' },
    { import = 'features.completion' },
    { import = 'features.git' },
    { import = 'features.editing' },
    { import = 'features.search' },
    { import = 'features.diagnostics' },
    { import = 'features.formatting' },
    { import = 'features.ai' },
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
