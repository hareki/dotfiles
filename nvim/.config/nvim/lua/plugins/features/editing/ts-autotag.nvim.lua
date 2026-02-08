return {
  'tronikelis/ts-autotag.nvim',
  ft = { 'html', 'xml', 'javascriptreact', 'typescriptreact' },
  opts = function()
    return {
      auto_rename = {
        enabled = true,
      },
    }
  end,
}
