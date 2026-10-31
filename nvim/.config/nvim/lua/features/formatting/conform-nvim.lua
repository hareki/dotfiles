return {
  'stevearc/conform.nvim',
  opts = function()
    local opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        toml = { 'taplo' },

        -- prettier's glimmer parser breaks Express handlebars, so the html server formats it
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

      -- prettier infers angular only for *.component.html; html mangles app.html's @if/@for blocks
      opts.formatters = {
        prettier = { options = { ft_parsers = { htmlangular = 'angular' } } },
      }
    end

    return opts
  end,
}
