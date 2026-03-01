local filetypes = {
  'css',
  'scss',
  'html',
  'json',

  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',

  'lua',
}

return {
  'catgoose/nvim-colorizer.lua',
  ft = filetypes,
  opts = function()
    return {
      filetypes = filetypes,
      options = {
        parsers = {
          css = true,
          css_fn = true,
          hex = {
            enable = true,
          },
          names = {
            enable = false,
          },
        },
      },
    }
  end,
}
