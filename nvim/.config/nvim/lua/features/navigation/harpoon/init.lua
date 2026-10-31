return {
  UI.which_key({
    specs = { '<leader>H', group = 'Pin File' },
    rules = { pattern = 'pin', icon = Conf.icons.tools.PIN, color = 'yellow' },
  }),

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    keys = function()
      local keys = {
        {
          '<leader>fp',
          function()
            local harpoon_utils = require('features.navigation.harpoon.utils')
            harpoon_utils.show_picker()
          end,
          desc = 'Pinned Files: Quick Menu',
        },
      }

      for current_index = 1, 5 do
        table.insert(keys, {
          '<leader>H' .. current_index,
          function()
            local harpoon_utils = require('features.navigation.harpoon.utils')
            harpoon_utils.pin(current_index)
          end,
          desc = 'Pin File to Slot ' .. current_index,
        })

        table.insert(keys, {
          '<leader>' .. current_index,
          function()
            local harpoon = require('harpoon')
            harpoon:list():select(current_index)
          end,
          desc = 'Go to Pin Slot ' .. current_index,
        })
      end

      return keys
    end,

    config = function()
      local harpoon = require('harpoon')
      local utils = require('features.navigation.harpoon.utils')
      harpoon:setup()

      -- Invalidate the statusline component on the only mutations utils.lua makes
      harpoon:extend({
        REMOVE = utils.refresh_statusline,
        REPLACE = utils.refresh_statusline,
      })
    end,
  },
}
