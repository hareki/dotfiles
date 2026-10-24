return {
  'stevearc/conform.nvim',
  opts = function()
    local opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        toml = { 'taplo' },

        -- prettier's glimmer parser rejects Express handlebars and rewrites quotes, so the html
        -- server formats it instead (see core/lsp/nvim-lspconfig/lsp/html.lua)
        handlebars = { lsp_format = 'fallback' },
      },
    }

    -- oxfmt already runs as an LSP server
    if Project.formatter == 'prettier' then
      local prettier_filetypes = Conf.filetypes.merge(
        Conf.filetypes.JS_ALL,
        Conf.filetypes.CSS,
        { 'html' },
        Conf.filetypes.ANGULAR,
        Conf.filetypes.MARKDOWN,
        Conf.filetypes.JSON,
        { 'yaml' }
      )
      for _, ft in ipairs(prettier_filetypes) do
        opts.formatters_by_ft[ft] = { 'prettier' }
      end

      -- prettier infers the angular parser only for *.component.html; Angular 20 style app.html
      -- would get the html parser, which mangles @if/@for control flow blocks
      opts.formatters = {
        prettier = { options = { ft_parsers = { htmlangular = 'angular' } } },
      }
    end

    return opts
  end,
}
