return {
  'stevearc/conform.nvim',
  opts = function()
    local formatter_groups = {
      prettier = {
        config = { 'prettier', stop_after_first = true },
        filetypes = {
          'javascript',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'css',
          'scss',
          'html',
          'markdown',
          'mdx',
          'json',
          'jsonc',
          'yaml',
        },
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
