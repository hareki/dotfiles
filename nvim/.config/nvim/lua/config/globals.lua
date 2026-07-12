_G.Defer = require('utils.lazy-require')

--- @module 'utils.notifier'
_G.Notifier = Defer.on_exported_call('utils.notifier')

--- @module 'config'
_G.Conf = require('config')

--- @module 'utils.ui'
_G.UI = require('utils.ui')

local project_config = require('utils.project-config')
_G.Project = project_config.get()
