return {
  opts = {},

  setup = function()
    local engine = require('utils.style-enforcers.engine')
    --- @module 'utils.style-enforcers.oxlint'
    local oxlint = Defer.on_exported_call('utils.style-enforcers.oxlint')

    engine.register_on_attach('oxlint', Conf.filetypes.JS_ALL, oxlint.run)
  end,
}
