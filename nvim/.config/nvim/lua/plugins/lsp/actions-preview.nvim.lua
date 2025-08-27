return {
  'aznhe21/actions-preview.nvim',
  opts = {
    telescope = {
      preview_title = require('plugins.editor.telescope.utils').preview_title,
      layout_config = {
        vertical = require('utils.ui').telescope_layout('md'),
      },
    },
  },
}
