_G.Defer = require('utils.lazy_require')

--- @module 'services.notifier'
_G.Notifier = Defer.on_exported_call('services.notifier')

-- Order matters if one config module is reading another
--- @class Conf
--- @field Filetypes config.filetypes
--- @field Icons config.icons
--- @field Priority config.priority
--- @field Picker config.picker
--- @field Size config.size
--- @field Cmp config.cmp
_G.Conf = {}
Conf.Filetypes = require('config.filetypes')
Conf.Icons = require('config.icons')
Conf.Priority = require('config.priority')
Conf.Picker = require('config.picker')
Conf.Size = require('config.size')
Conf.Cmp = require('config.cmp')

--- @module 'utils.ui'
_G.UI = require('utils.ui')

--- @module 'services.statusline'
_G.Statusline = require('services.statusline')

local project_config = require('utils.project_config')
_G.Project = project_config.get()
