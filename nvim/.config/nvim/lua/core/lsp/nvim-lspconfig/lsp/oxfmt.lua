local oxfmt_registered = false

return {
  opts = function()
    local oxfmt_cfg = vim.lsp.config.oxfmt or {}
    local base_on_oxfmt_attach = oxfmt_cfg.on_attach

    return {
      on_attach = function(client, bufnr)
        if base_on_oxfmt_attach then
          base_on_oxfmt_attach(client, bufnr)
        end

        if oxfmt_registered then
          return
        end

        local engine = require('utils.style-enforcers.engine')
        local oxfmt = require('utils.style-enforcers.oxfmt')

        -- Subset of oxfmt LSP's advertised filetypes that we want it to own.
        -- Excludes astro/mdx (oxfmt LSP doesn't support them) and toml (taplo owns it).
        local oxfmt_filetypes = Conf.filetypes.merge(
          Conf.filetypes.JS, -- js/ts(x), no astro
          Conf.filetypes.CSS, -- css/scss/less
          { 'html' },
          { 'markdown' }, -- no mdx
          Conf.filetypes.JSON, -- json/jsonc/json5
          { 'yaml' }
        )

        -- Run before lint-fix steps so oxlint's on-disk fixAll sees formatted content.
        engine.register('oxfmt', oxfmt_filetypes, oxfmt.run, { order = 10 })

        oxfmt_registered = true
      end,
    }
  end,
}
