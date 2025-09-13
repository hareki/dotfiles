local filetypes =
  { 'css', 'scss', 'html', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }

return {
  'catgoose/nvim-colorizer.lua',
  ft = filetypes,
  opts = {
    filetypes = filetypes,
    user_default_options = {
      names = false,
      css = true,
    },
  },
}
