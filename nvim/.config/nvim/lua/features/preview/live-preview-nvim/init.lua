local prefix = 'Live Preview: '

return {
  UI.which_key({
    specs = { '<leader>p', group = 'Live Preview' },
    rules = { pattern = 'live preview', icon = Conf.icons.tools.LIVE_PREVIEW, color = 'purple' },
  }),

  {
    'hareki/live-preview.nvim',
    cmd = 'LivePreview',
    keys = {
      {
        '<leader>pp',
        function()
          local utils = require('features.preview.live-preview-nvim.utils')
          utils.start()
        end,
        desc = prefix .. 'Start',
      },
      {
        '<leader>px',
        '<cmd>LivePreview close<cr>',
        desc = prefix .. 'Stop',
      },
      {
        '<leader>fP',
        function()
          local utils = require('features.preview.live-preview-nvim.utils')
          utils.pick()
        end,
        desc = prefix .. 'Find File',
      },
    },

    opts = function()
      return {
        sync_scroll = false,
      }
    end,

    config = function(_, opts)
      local utils = require('features.preview.live-preview-nvim.utils')
      utils.setup(opts)
    end,
  },
}
