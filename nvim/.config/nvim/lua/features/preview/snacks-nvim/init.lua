local media = Defer.on_exported_call('features.preview.snacks-nvim.utils')

return {
  {
    'snacks.nvim',
    -- Startup hook in place of `init`, which lazy.nvim runs for a single fragment only:
    -- opts resolve right before snacks' setup(), and returning nil keeps the merged opts
    opts = media.setup_audio_viewer,
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
            -- snacks' default plus the define: ImageMagick asks ffmpeg for WebP frames, which
            -- Homebrew's ffmpeg (no libwebp) can't encode; PAM needs none, and only video reads it
            default = {
              '-define',
              'video:intermediate-format=pam',
              '{src}[0]',
              '-scale',
              '1920x1080>',
            },
          },
        },
        -- Inline images render as virtual lines, which are tricky to scroll, so keep them short
        doc = {
          -- Static number: snacks.image does no callable resolution here
          max_width = UI.layout.popup('full').width,
          max_height = 15,
          excluded_filetypes = Conf.filetypes.merge(Conf.filetypes.JS_ALL, Conf.filetypes.CSS),
        },
      },

      picker = {
        -- Stands in for snacks' file previewer wherever a source sets no previewer of its own
        preview = media.preview_file,
      },
    },
  },
}
