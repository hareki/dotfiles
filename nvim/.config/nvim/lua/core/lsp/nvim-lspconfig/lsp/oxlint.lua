local oxlint_registered = false

return {
  opts = function()
    local oxlint_cfg = vim.lsp.config.oxlint or {}
    local base_on_oxlint_attach = oxlint_cfg.on_attach

    return {
      on_attach = function(client, bufnr)
        if base_on_oxlint_attach then
          base_on_oxlint_attach(client, bufnr)
        end

        if oxlint_registered then
          return
        end

        local engine = require('utils.style-enforcers.engine')
        local oxlint = require('utils.style-enforcers.oxlint')

        engine.register('oxlint', Conf.filetypes.JS_ALL, oxlint.run)

        oxlint_registered = true
      end,
    }
  end,
}
