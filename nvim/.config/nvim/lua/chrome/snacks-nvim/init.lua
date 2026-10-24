local zen = Defer.on_exported_call('chrome.snacks-nvim.utils')

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
              width = UI.layout.popup_fn('sm', true).width,
              -- Neutralize the select preset's min_width=80/max_width=100,
              -- which would otherwise clamp the function-valued width
              min_width = 0,
              max_width = math.huge,
            },
          },
        },
      },
    },

    styles = {
      input = UI.layout.popup_fn('input'),
      zen = vim.tbl_extend('force', UI.layout.popup_fn('vertical_md'), {
        -- transparent = false drops winblend, so the backdrop is opaque and hides the window behind
        -- the popup outright instead of dimming it; utils.lua anchors its geometry to that window
        backdrop = { transparent = false, blend = 0 },
        border = 'rounded',
        title = ' Zen ',
        -- Zen's zindex 40 ties satellite.nvim's bars over a normal window; 50 clears them while
        -- staying under styles.float (52), so pickers opened from zen stay on top
        zindex = 50,
      }),
    },
  },
}
