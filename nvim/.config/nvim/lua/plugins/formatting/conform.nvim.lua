return {
  'stevearc/conform.nvim',
  opts = function()
    local formatter_groups = {
      prettier = {
        filetypes = {
          'javascript',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'css',
          'scss',
          'html',
          'json',
          'jsonc',
          'yaml',
          'markdown',
          'mdx',
        },
        config = { 'prettierd', 'prettier', stop_after_first = true },
      },
      stylua = {
        filetypes = { 'lua' },
        config = { 'stylua' },
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
