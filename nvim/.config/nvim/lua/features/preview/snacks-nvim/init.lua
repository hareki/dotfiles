--- @module 'features.preview.snacks-nvim.audio-page'
local audio_page = Defer.on_exported_call('features.preview.snacks-nvim.audio-page')

--- @module 'features.preview.snacks-nvim.hover-image'
local hover_image = Defer.on_exported_call('features.preview.snacks-nvim.hover-image')

return {
  {
    'snacks.nvim',
    -- Startup hook: lazy.nvim runs `init` for one fragment only (see AGENTS.md "Split Plugins")
    opts = audio_page.setup_audio_viewer,
  },

  {
    'snacks.nvim',
    keys = {
      { 'gi', hover_image.toggle, desc = 'Hover Image' },
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
        preview = audio_page.preview_file,
      },
    },
  },
}
