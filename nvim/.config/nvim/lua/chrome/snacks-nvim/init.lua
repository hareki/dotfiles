--- @module 'chrome.snacks-nvim.zen'
local zen = Defer.on_exported_call('chrome.snacks-nvim.zen')

return {
  'snacks.nvim',
  keys = {
    { '<leader>>', zen.toggle, desc = 'Toggle Zen Mode' },
  },

  opts = {
    input = { enabled = true },
    zen = {
      enabled = true,
      -- Snacks.dim greys out everything outside the current scope
      toggles = { dim = false },
      on_open = zen.on_open,
      on_close = zen.on_close,
    },

    picker = {
      sources = {
        select = {
          layout = {
            layout = {
              width = UI.layout.picker_fn('sm').width,
              -- The select preset's min_width=80/max_width=100 would clamp the function width
              min_width = 0,
              max_width = math.huge,
            },
          },
        },
      },
    },

    styles = {
      input = UI.layout.float_fn('input'),
      zen = vim.tbl_extend('force', UI.layout.float_fn('vertical_md'), {
        -- transparent = false drops winblend, so the backdrop is opaque and hides the window behind
        -- the float outright instead of dimming it; zen.lua anchors its geometry to that window
        backdrop = { transparent = false, blend = 0 },
        border = 'rounded',
        title = ' Zen ',
        zindex = Conf.zindex.ZEN,
      }),
    },
  },
}
