return {
  'hareki/actions-preview.nvim',
  opts = {
    highlight_command = {
      function()
        return require('actions-preview.highlight').delta()
      end,
    },
    telescope = {
      preview_title = require('plugins.editor.telescope.utils').preview_title,
      layout_config = {
        vertical = require('utils.ui').telescope_layout('md'),
      },
    },
    refactoring = {
      enabled = true,
    },
  },
}
