return {
  'stevearc/conform.nvim',
  opts = function()
    local opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        toml = { 'taplo' },

        -- prettier parses handlebars with Ember's glimmer parser, which rejects the
        -- Express flavor (blocks inside attributes) and rewrites HTML attribute
        -- quotes per `singleQuote`; vscode-html-language-server handles it instead
        -- (see the format settings in core/lsp/nvim-lspconfig/lsp/html.lua)
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

      -- prettier infers the angular parser only for *.component.html; Angular 20
      -- style templates (app.html) would fall back to the html parser, which
      -- mangles @if/@for control flow blocks
      opts.formatters = {
        prettier = { options = { ft_parsers = { htmlangular = 'angular' } } },
      }
    end

    return opts
  end,
}
