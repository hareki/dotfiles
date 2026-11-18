--- @module 'core.snacks-nvim.floating-terminal'
local floating_terminal = Defer.on_exported_call('core.snacks-nvim.floating-terminal')

-- Base spec: feature config lives in `snacks-nvim` fragments (AGENTS.md "Split Plugins")
return {
  UI.catppuccin.integration('snacks'),

  {
    'hareki/snacks.nvim',
    lazy = false,
    -- This plugin has many responsibilities, should load it early to setup stuff correctly
    priority = Conf.priority.CORE,

    keys = {
      {
        '<A-t>',
        floating_terminal.toggle,
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
