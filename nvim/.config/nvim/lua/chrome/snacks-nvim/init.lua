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
        -- transparent = false makes snacks drop winblend entirely, so the
        -- backdrop is an opaque window (painted in the Normal background, or
        -- in nothing under our transparent colorscheme) and the window behind
        -- the popup is hidden outright rather than dimmed, then restored on
        -- close. Its geometry is anchored to that window in utils.lua
        backdrop = { transparent = false, blend = 0 },
        border = 'rounded',
        title = ' Zen ',
        -- The zen style pins zindex to 40, tying with satellite.nvim's bars over a normal
        -- window (its default; it only bumps to parent + 1 over a float, hence the 51 noted on
        -- styles.float in core/snacks-nvim/init.lua). 50 clears them while staying under
        -- styles.float (52) so pickers from zen stay on top
        zindex = 50,
      }),
    },
  },
}
