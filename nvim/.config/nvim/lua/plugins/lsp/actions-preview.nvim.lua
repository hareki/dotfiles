return {
  'hareki/actions-preview.nvim',
  opts = {
    highlight_command = {
      function()
        return require('actions-preview.highlight').delta()
      end,
    },
    telescope = {
      preview_title = require('configs.common').preview_title.telescope,
      layout_config = {
        vertical = require('utils.ui').telescope_layout('md'),
      },
    },
    refactoring = {
      enabled = true,
    },
  },
}
