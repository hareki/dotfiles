_G.Defer = require('utils.lazy-require')

---@module 'utils.notifier'
_G.Notifier = Defer.on_exported_call('utils.notifier')

-- No need to defer these because they are needed during startup anyway
_G.Catppuccin = require('utils.ui').catppuccin
_G.Icons = require('config.icons')
