return {
  'aznhe21/actions-preview.nvim',
  opts = {
    telescope = {
      preview_title = require('configs.common').preview_title,
      layout_config = {
        vertical = require('utils.ui').telescope_layout('sm'),
      },
    },
  },
}
