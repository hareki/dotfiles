_G.Defer = require('utils.lazy-require')

--- @module 'utils.notifier'
_G.Notifier = Defer.on_exported_call('utils.notifier')

-- Order matters if one config module is reading another
--- @class Conf
--- @field filetypes config.filetypes
--- @field icons config.icons
--- @field priority config.priority
--- @field picker config.picker
--- @field size config.size
--- @field cmp config.completion
_G.Conf = {}
Conf.filetypes = require('config.filetypes')
Conf.icons = require('config.icons')
Conf.priority = require('config.priority')
Conf.picker = require('config.picker')
Conf.size = require('config.size')
Conf.cmp = require('config.completion')

--- @module 'utils.ui'
_G.UI = require('utils.ui')

local project_config = require('utils.project-config')
_G.Project = project_config.get()
