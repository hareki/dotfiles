return {
  'hareki/actions-preview.nvim',
  opts = function()
    return {
      highlight_command = {
        function()
          return require('actions-preview.highlight').delta()
        end,
      },
      telescope = {
        preview_title = require('configs.picker').telescope_preview_title,
        layout_config = {
          vertical = require('utils.ui').telescope_layout('md'),
        },
      },
      refactoring = {
        enabled = true,
      },
    }
  end,
}
