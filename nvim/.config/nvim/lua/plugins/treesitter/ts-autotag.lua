-- Automatically add closing tags for HTML and JSX
return {
  'tronikelis/ts-autotag.nvim',
  ft = { 'html', 'xml', 'javascriptreact', 'typescriptreact' },
  opts = {
    auto_rename = {
      enabled = true,
    },
  },
}
