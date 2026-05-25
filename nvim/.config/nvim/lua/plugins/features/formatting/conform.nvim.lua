return {
  'stevearc/conform.nvim',
  opts = function()
    local js_formatter_name = Project.formatter == 'oxfmt' and 'oxfmt' or 'prettier'

    -- JS-family filetypes run the chosen formatter, then oxlint --fix when the
    -- project linter is oxlint (replaces the DIY oxc.fixAll LSP runner).
    local js_all_config = { js_formatter_name, stop_after_first = true }
    if Project.linter == 'oxlint' then
      js_all_config = { js_formatter_name, 'oxlint' }
    end

    local formatter_groups = {
      js_all = {
        config = js_all_config,
        filetypes = Filetypes.js_all,
      },
      [js_formatter_name] = {
        config = { js_formatter_name, stop_after_first = true },
        filetypes = Filetypes.merge(
          Filetypes.css,
          { 'html' },
          Filetypes.markdown,
          Filetypes.json,
          { 'yaml' }
        ),
      },
      stylua = {
        filetypes = { 'lua' },
        config = { 'stylua' },
      },
      taplo = {
        filetypes = { 'toml' },
        config = { 'taplo' },
      },
    }

    local formatters_by_ft = {}
    for _, group in pairs(formatter_groups) do
      for _, ft in ipairs(group.filetypes) do
        formatters_by_ft[ft] = group.config
      end
    end

    return { formatters_by_ft = formatters_by_ft }
  end,
}
