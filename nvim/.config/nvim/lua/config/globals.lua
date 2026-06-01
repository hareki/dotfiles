_G.Defer = require('utils.lazy_require')

---@module 'services.notifier'
_G.Notifier = Defer.on_exported_call('services.notifier')

-- No need to defer these because they are needed during startup anyway
_G.Filetypes = require('config.filetypes')
_G.Icons = require('config.icons')
_G.Priority = require('config.priority')

local ui = require('utils.ui')
_G.Catppuccin = ui.catppuccin
_G.WhichKey = ui.which_key

local project_config = require('utils.project_config')
_G.Project = project_config.get()
