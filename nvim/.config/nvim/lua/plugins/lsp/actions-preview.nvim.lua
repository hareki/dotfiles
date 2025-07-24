return {
  'aznhe21/actions-preview.nvim',
  opts = {
    telescope = {
      preview_title = require('configs.common').PREVIEW_TITLE,
      layout_config = {
        vertical = require('utils.ui').telescope_layout_config('sm'),
      },
    },
  },
}
