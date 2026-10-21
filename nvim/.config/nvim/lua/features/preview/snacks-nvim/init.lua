local image = Defer.on_exported_call('features.preview.snacks-nvim.utils')

return {
  'snacks.nvim',
  keys = {
    { 'gi', image.hover_image, desc = 'Hover Image' },
  },

  opts = {
    image = {
      enabled = true,
      convert = {
        notify = true,
        magick = {
          -- snacks' default plus the define: ImageMagick takes video frames from ffmpeg as
          -- WebP by default, which Homebrew's ffmpeg (built without libwebp) can't encode.
          -- PAM needs no extra library, and only the video coder reads the define
          default = {
            '-define',
            'video:intermediate-format=pam',
            '{src}[0]',
            '-scale',
            '1920x1080>',
          },
        },
      },
      -- Inline images are inserted as virtual lines, and virtual lines are tricky to scroll, so better keep it short
      doc = {
        -- Static number: snacks.image does no callable resolution here
        max_width = UI.layout.popup('full').width,
        max_height = 15,
        excluded_filetypes = Conf.filetypes.merge(Conf.filetypes.JS_ALL, Conf.filetypes.CSS),
      },
    },
  },
}
