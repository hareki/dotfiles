_G.Defer = require('utils.lazy-require')

---@module 'services.notifier'
_G.Notifier = Defer.on_exported_call('services.notifier')

-- No need to defer these because they are needed during startup anyway
local ui = require('utils.ui')
_G.Catppuccin = ui.catppuccin
_G.WhichKey = ui.which_key
_G.Filetypes = require('config.filetypes')
_G.Icons = require('config.icons')
_G.Priority = require('config.priority')
