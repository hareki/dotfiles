_G.Defer = require('utils.lazy-require')

---@module 'services.notifier'
_G.Notifier = Defer.on_exported_call('services.notifier')

-- No need to defer these because they are needed during startup anyway
_G.Catppuccin = require('utils.ui').catppuccin
_G.Icons = require('config.icons')
_G.Priority = require('config.priority')
