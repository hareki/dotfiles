require('configs.core.ensure-lazy')

-- [[ Configure and install plugins ]]
Util.custom_lazy_events()
local lg = Constant.ui.popup_size.lg
require('lazy').setup({
  version = '*',
  ui = {
    size = { width = lg.WIDTH, height = lg.HEIGHT },
    border = 'rounded',
    backdrop = 100,
    title = ' Lazy ',
  },
  spec = {
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
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})
