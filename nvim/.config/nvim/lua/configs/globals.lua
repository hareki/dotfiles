_G.notifier = setmetatable({}, {
  __index = function(_, key)
    local notifier_module = require('utils.notifier')
    _G.notifier = notifier_module
    return notifier_module[key]
  end,
})
