--- @module 'core.snacks-nvim.terminals'
local terminals = Defer.on_exported_call('core.snacks-nvim.terminals')

-- Base spec: feature config lives in `snacks-nvim` fragments (docs/conventions/split-plugins.md)
return {
  UI.catppuccin.integration('snacks'),

  {
    'hareki/snacks.nvim',
    lazy = false,
    -- Set up early, as Snacks' README asks: some plugins rely on the autocmds its setup creates
    priority = Conf.priority.CORE,

    keys = {
      {
        '<A-t>',
        terminals.toggle_floating,
        mode = { 'n', 'x', 't', 'i' },
        desc = 'Toggle Floating Terminal',
      },
    },

    opts = {
      bigfile = { enabled = true },

      styles = {
        float = { zindex = Conf.zindex.FLOAT },
        terminal = vim.tbl_extend('force', UI.layout.float_fn('lg'), {
          title = ' Terminal ',
          border = 'rounded',
          zindex = Conf.zindex.PANEL,
        }),
      },
    },
  },
}
