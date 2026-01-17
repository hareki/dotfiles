return {
  '3rd/image.nvim',
  build = false, -- Skip rock build: https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
  opts = function()
    return {
      backend = 'kitty',
      processor = 'magick_cli',
    }
  end,
}
