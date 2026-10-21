local media = Defer.on_exported_call('features.preview.snacks-nvim.utils')

return {
  {
    'snacks.nvim',
    -- Startup hook in place of `init`, which lazy.nvim runs for a single fragment only:
    -- opts resolve right before snacks' setup(), and returning nil keeps the merged opts
    opts = function()
      media.setup_audio_viewer()
    end,
  },

  {
    'snacks.nvim',
    keys = {
      { 'gi', media.hover_image, desc = 'Hover Image' },
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
  },
}
