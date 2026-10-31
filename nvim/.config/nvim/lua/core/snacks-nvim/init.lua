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
      float = {
        -- Slightly higher than satellite.nvim scrollbar (51)
        zindex = 52,
      },
      terminal = vim.tbl_extend('force', UI.layout.popup_fn('lg'), {
        title = ' Terminal ',
        border = 'rounded',
        -- Above pickers and nvim-tree; pickers only stack over floats below 100
        zindex = 100,
      }),
    },
  },
}
