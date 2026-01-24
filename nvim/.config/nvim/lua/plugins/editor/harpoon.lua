return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  keys = function()
    local keys = {
      {
        '<leader>fp',
        function()
          local harpoon_picker = require('plugins.ui.snacks.pickers.harpoon')
          harpoon_picker.show()
        end,
        desc = 'Harpoon: Quick Menu',
      },
    }

    for current_index = 1, 5 do
      table.insert(keys, {
        '<leader>H' .. current_index,
        function()
          local harpoon = require('harpoon')
          local path = require('utils.path')
          local list = harpoon:list()

          local new_item = list.config.create_list_item(list.config)
          local old_item = list:get(current_index)

          local new_filepath = vim.api.nvim_buf_get_name(0)
          local new_relpath = path.get_relative_path(new_filepath, vim.uv.cwd() or vim.fn.getcwd())

          local old_filepath = old_item and old_item.value or nil
          local old_relpath = old_filepath
              and path.get_relative_path(old_filepath, vim.uv.cwd() or vim.fn.getcwd())
            or nil

          if old_item and old_item.value == new_item.value then
            Notifier.warn({
              { new_relpath, 'NotifyWARNTitle' },
              { '\nis already in slot ', 'Normal' },
              { tostring(current_index), 'NotifyWARNTitle' },
            }, { title = 'harpoon' })
            return
          end

          -- Check if new_item already exists at another index
          local old_index = nil
          local length = list:length()
          for index = 1, length do
            if index ~= current_index then
              local existing_item = list:get(index)
              if existing_item and existing_item.value == new_item.value then
                old_index = index
                break
              end
            end
          end

          -- Replace the item at slot i with new_item. If new_item exists in another slot, it is removed from that slot first.
          list:replace_at(current_index, new_item)

          local item_exists_elsewhere = old_index ~= nil
          local slot_has_different_item = old_relpath ~= nil and old_relpath ~= new_relpath
          local hl_title = (item_exists_elsewhere or slot_has_different_item) and 'NotifyWARNTitle'
            or 'NotifyINFOTitle'

          if item_exists_elsewhere then
            Notifier.warn({
              { 'Moved ', 'Normal' },
              { new_relpath, hl_title },
              { '\nfrom slot ', 'Normal' },
              { tostring(old_index), hl_title },
              { ' to ', 'Normal' },
              { tostring(current_index), hl_title },
            }, { title = 'harpoon' })
          elseif slot_has_different_item then
            Notifier.warn({
              { 'Replaced ', 'Normal' },
              { old_relpath, hl_title },
              { '\nwith ', 'Normal' },
              { new_relpath, hl_title },
              { '\nfor slot ', 'Normal' },
              { tostring(current_index), hl_title },
            }, { title = 'harpoon' })
          else
            -- Slot was empty, new file added
            Notifier.info({
              { 'Added ', 'Normal' },
              { new_relpath, hl_title },
              { '\ninto slot ', 'Normal' },
              { tostring(current_index), hl_title },
            }, { title = 'harpoon' })
          end

          local lualine_utils = require('plugins.ui.lualine.utils')
          lualine_utils.refresh_statusline()
        end,
        desc = 'Harpoon Current File to Slot ' .. current_index,
      })

      table.insert(keys, {
        '<leader>' .. current_index,
        function()
          require('harpoon'):list():select(current_index)
        end,
        desc = 'Harpoon: File ' .. current_index,
      })
    end

    return keys
  end,
  opts = function()
    local ui = require('utils.ui')
    local menu_popup = ui.popup_config('sm', true)

    return {
      menu = {
        width = menu_popup.width,
      },
      settings = {
        save_on_toggle = true,
      },
    }
  end,
}
