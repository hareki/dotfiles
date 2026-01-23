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

    for i = 1, 5 do
      table.insert(keys, {
        '<leader>H' .. i,
        function()
          local harpoon = require('harpoon')
          local path = require('utils.path')
          local list = harpoon:list()
          local item = list.config.create_list_item(list.config)

          local filepath = vim.api.nvim_buf_get_name(0)
          local relpath = path.get_relative_path(filepath, vim.uv.cwd() or vim.fn.getcwd())

          local existing_item = list:get(i)
          local old_filepath = existing_item and existing_item.value or nil
          local old_relpath = old_filepath
              and path.get_relative_path(old_filepath, vim.uv.cwd() or vim.fn.getcwd())
            or nil

          if existing_item and existing_item.value == item.value then
            Notifier.warn({
              { relpath, 'NotifyWARNTitle' },
              { '\nis already in slot ', 'Normal' },
              { tostring(i), 'NotifyWARNTitle' },
            }, { title = 'harpoon' })
            return
          end

          local _, existing_index = list:get_by_value(item.value)
          if existing_index and existing_index ~= i then
            list:remove_at(existing_index)
          end

          if existing_item then
            list:remove_at(i)
          end

          list.items[i] = item

          if old_relpath then
            Notifier.warn({
              { 'Replaced ', 'Normal' },
              { old_relpath, 'NotifyWARNTitle' },
              { '\nwith ', 'Normal' },
              { relpath, 'NotifyWARNTitle' },
              { '\nfor slot ', 'Normal' },
              { tostring(i), 'NotifyWARNTitle' },
            }, { title = 'harpoon' })
          else
            Notifier.info({
              { 'Added ', 'Normal' },
              { relpath, 'NotifyINFOTitle' },
              { '\ninto slot ', 'Normal' },
              { tostring(i), 'NotifyINFOTitle' },
            }, { title = 'harpoon' })
          end

          local lualine_utils = require('plugins.ui.lualine.utils')
          lualine_utils.refresh_statusline()
        end,
        desc = 'Harpoon Current File to Slot ' .. i,
      })

      table.insert(keys, {
        '<leader>' .. i,
        function()
          require('harpoon'):list():select(i)
        end,
        desc = 'Harpoon: File ' .. i,
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
