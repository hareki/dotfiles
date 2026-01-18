_G.Defer = require('utils.lazy-require')

---@module 'utils.notifier'
_G.Notifier = Defer.on_exported_call('utils.notifier')
-- Called Immediately anyway during lazy.nvim startup
_G.Catppuccin = require('utils.ui').catppuccin
