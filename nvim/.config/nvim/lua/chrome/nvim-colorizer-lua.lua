local filetypes = Filetypes.merge(Filetypes.css, Filetypes.js, { 'html', 'json', 'lua', 'toml' })

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
          hex = { enable = true },
          css_var = { enable = false },
          names = { enable = false },
        },
      },
    }
  end,
}
