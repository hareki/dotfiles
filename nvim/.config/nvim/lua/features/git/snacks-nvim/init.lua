local lazygit = Defer.on_exported_call('features.git.snacks-nvim.utils')

return {
  {
    'snacks.nvim',
    -- Startup hook in place of `init`, which lazy.nvim runs for a single fragment only:
    -- opts resolve right before snacks' setup(), and returning nil keeps the merged opts
    opts = function()
      lazygit.setup()
    end,
  },

  {
    'snacks.nvim',
    keys = {
      {
        '<leader>fgb',
        function()
          Snacks.picker.git_branches()
        end,
        desc = 'Find Git Branches',
      },
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
        lazygit = vim.tbl_extend('force', UI.layout.popup_fn('full'), {
          backdrop = false,
          border = 'rounded',
          title = ' Git Client ',
          title_pos = 'center',
        }),
      },
    },
  },
}
