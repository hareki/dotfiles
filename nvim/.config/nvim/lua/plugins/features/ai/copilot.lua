return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'VeryLazy',
  opts = function()
    local path = require('utils.path')
    local initial_path = path.get_initial_path()

    return {
      workspace_folders = { initial_path },
      filetypes = { markdown = true, help = true },

      nes = { enabled = false },
      panel = { enabled = false },
      suggestion = {
        enabled = false,
        auto_trigger = false,
        hide_during_completion = true,
      },
    }
  end,
}
