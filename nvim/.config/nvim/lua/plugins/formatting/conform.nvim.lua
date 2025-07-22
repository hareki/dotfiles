return {
  'stevearc/conform.nvim',
  opts = function()
    local perttier_ft = {}
    for _, ft in ipairs(Const.JS_FILETYPES) do
      perttier_ft[ft] = { 'prettierd', 'prettier', stop_after_first = true }
    end

    return {
      formatters_by_ft = vim.tbl_extend('error', {
        lua = { 'stylua' },
      }, perttier_ft),
    }
  end,
}
