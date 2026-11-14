-- Base spec: feature config lives in `snacks-nvim` fragments (AGENTS.md "Split Plugins")
return {
  'hareki/snacks.nvim',
  lazy = false,
  -- This plugin has many responsibilities, should load it early to setup stuff correctly
  priority = Conf.priority.CORE,

  keys = {
    {
      '<A-t>',
      function()
        Snacks.terminal.toggle(nil, { win = { position = 'float' } })
      end,
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
}
