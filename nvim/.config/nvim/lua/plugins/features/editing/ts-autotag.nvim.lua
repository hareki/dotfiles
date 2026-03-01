local filetypes = { 'html', 'xml', 'javascriptreact', 'typescriptreact', 'astro' }

return {
  'tronikelis/ts-autotag.nvim',
  ft = filetypes,
  opts = function()
    return {
      auto_rename = {
        enabled = true,
      },
      filetypes = filetypes,
    }
  end,
}
