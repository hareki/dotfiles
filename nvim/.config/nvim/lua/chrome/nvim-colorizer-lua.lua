local FILETYPES = Conf.filetypes.merge(
  Conf.filetypes.CSS,
  Conf.filetypes.JS,
  Conf.filetypes.ANGULAR,
  { 'html', 'json', 'lua', 'toml', 'ghostty', 'yaml' }
)

return {
  'catgoose/nvim-colorizer.lua',
  ft = FILETYPES,
  opts = function()
    return {
      filetypes = FILETYPES,
      options = {
        parsers = {
          css = true, -- Preset: names, hex, rgb, hsl, oklch, css_var (narrowed below)
          css_var = { enable = false },
          names = { enable = false },
        },
      },
    }
  end,
}
