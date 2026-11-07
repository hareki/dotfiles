local lazygit = Defer.on_exported_call('features.git.snacks-nvim.utils')

--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')

return {
  {
    'snacks.nvim',
    -- Startup hook: lazy.nvim runs `init` for one fragment only (see AGENTS.md "Split Plugins")
    opts = lazygit.setup,
  },

  {
    'snacks.nvim',
    keys = {
      { '<leader>fgb', picker.git_branches, desc = 'Find Git Branches' },
      {
        '<A-g>',
        lazygit.toggle,
        mode = { 'n', 'x', 't', 'i' },
        desc = 'Toggle Lazygit',
      },
    },

    opts = {
      lazygit = { enabled = true, configure = false },
    },
  },
}
