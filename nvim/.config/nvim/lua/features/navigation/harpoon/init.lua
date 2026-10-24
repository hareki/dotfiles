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

    opts = function()
      return {
        settings = {
          save_on_toggle = true,
        },
      }
    end,

    config = function(_, opts)
      local harpoon = require('harpoon')
      harpoon.setup(opts)

      -- Some mutations keep the list length (replace_at, menu-save reorder), so the statusline's
      -- (buf, length) cache key misses them; invalidate on harpoon's mutation events instead
      local function refresh_component()
        local harpoon_component = require('chrome.lualine-nvim.components.harpoon')
        harpoon_component.invalidate()
        UI.statusline.refresh()
      end

      harpoon:extend({
        ADD = refresh_component,
        REMOVE = refresh_component,
        REPLACE = refresh_component,
        LIST_CHANGE = refresh_component,
      })
    end,
  },
}
