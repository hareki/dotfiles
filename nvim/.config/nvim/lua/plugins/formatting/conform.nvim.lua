return {
  'stevearc/conform.nvim',
  opts = function()
    local perttier_filetypes = {}
    local js_filetypes = {
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
    }
    for _, ft in ipairs(js_filetypes) do
      perttier_filetypes[ft] = { 'prettierd', 'prettier', stop_after_first = true }
    end

    return {
      formatters_by_ft = vim.tbl_extend('error', {
        lua = { 'stylua' },
      }, perttier_filetypes),
    }
  end,
}
