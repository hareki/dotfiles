return {
  UI.catppuccin(function()
    return {
      TroubleNormal = { link = 'NormalFloat' },
      TroublePreview = { link = 'Search' },
      TroubleIconDirectory = { link = 'Directory' },
    }
  end, 'trouble.nvim'),

  {
    'hareki/trouble.nvim',
    cmd = { 'Trouble' },
    keys = function()
      local utils = require('features.diagnostics.trouble-nvim.utils')

      return {
        {
          '[q',
          function()
            utils.jump('prev')
          end,
          desc = 'Previous Trouble/Quickfix Item',
        },
        {
          ']q',
          function()
            utils.jump('next')
          end,
          desc = 'Next Trouble/Quickfix Item',
        },
      }
    end,

    opts = function()
      local utils = require('features.diagnostics.trouble-nvim.utils')
      local side_preview = UI.layout.side_preview()
      local panel_cols = UI.layout.side_size('side_panel', 'md')

      return {
        auto_refresh = false,
        win = { position = 'right', size = panel_cols },

        icons = {
          folder_closed = Conf.icons.file_tree.FOLDER,
          folder_open = Conf.icons.file_tree.FOLDER_EMPTY_OPEN,
        },

        preview = {
          type = 'float',
          relative = 'win',
          border = 'rounded',
          title = Conf.picker.PREVIEW_TITLE,
          title_pos = 'center',
          -- Fractional row: trouble resolves it against the parent on every open, so centering
          -- survives resizes; a negative col counts from the panel's right edge, hence the shift
          position = { 0.5, side_preview.col - panel_cols },
          size = {
            width = side_preview.width,
            height = side_preview.height,
          },
          zindex = 200,

          reuse_loaded_buf = false,
          notify_on_toggle = false,
          close_on_non_item = true,
        },

        keys = {
          ['<Tab>'] = {
            action = utils.toggle_focus,
            desc = 'Toggle Focus Between List and Preview',
          },
          B = 'toggle_preview',
        },
      }
    end,
  },
}
