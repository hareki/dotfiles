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

      styles = {
        -- Snacks.lazygit opens a Snacks terminal: border and zindex come from styles.terminal
        lazygit = vim.tbl_extend('force', UI.layout.popup_fn('full'), {
          backdrop = false,
          title = ' Git Client ',
        }),
      },
    },
  },
}
