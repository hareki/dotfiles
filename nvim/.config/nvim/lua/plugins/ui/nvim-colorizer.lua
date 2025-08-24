return {
  'catgoose/nvim-colorizer.lua',
  event = 'LazyFile',
  opts = {
    filetypes = {
      '*',
      '!lazy',
      '!DiffviewFiles',
      '!DiffviewFileHistory',
    },
    user_default_options = {
      names = false,
      css = true,
    },
  },
}
