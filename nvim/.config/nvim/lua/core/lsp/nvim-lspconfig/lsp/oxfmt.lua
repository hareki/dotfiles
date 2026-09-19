return {
  opts = {},

  setup = function()
    local engine = require('utils.style-enforcers.engine')
    --- @module 'utils.style-enforcers.oxfmt'
    local oxfmt = Defer.on_exported_call('utils.style-enforcers.oxfmt')

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
    engine.register_on_attach('oxfmt', oxfmt_filetypes, oxfmt.run, { order = 10 })
  end,
}
