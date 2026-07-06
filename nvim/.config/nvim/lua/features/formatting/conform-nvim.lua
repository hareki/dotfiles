return {
  'stevearc/conform.nvim',
  opts = function()
    local use_prettier = Project.formatter == 'prettier'

    local formatter_groups = {
      stylua = {
        filetypes = { 'lua' },
        config = { 'stylua' },
      },
      taplo = {
        filetypes = { 'toml' },
        config = { 'taplo' },
      },
    }

    -- oxfmt already runs as an LSP server
    if use_prettier then
      formatter_groups.prettier = {
        config = { 'prettier', stop_after_first = true },
        filetypes = Conf.Filetypes.merge(
          Conf.Filetypes.JS_ALL,
          Conf.Filetypes.CSS,
          { 'html' },
          Conf.Filetypes.MARKDOWN,
          Conf.Filetypes.JSON,
          { 'yaml' }
        ),
      }
    end

    local formatters_by_ft = {}
    for _, group in pairs(formatter_groups) do
      for _, ft in ipairs(group.filetypes) do
        formatters_by_ft[ft] = group.config
      end
    end

    return { formatters_by_ft = formatters_by_ft }
  end,
}
