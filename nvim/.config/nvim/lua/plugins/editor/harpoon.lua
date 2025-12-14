return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  opts = function()
    local menu_popup = require('utils.ui').popup_config('sm', true)
    return {
      menu = {
        width = menu_popup.width,
      },
      settings = {
        save_on_toggle = true,
      },
    }
  end,
  keys = function()
    local keys = {
      {
        '<leader>H',
        function()
          local harpoon = require('harpoon')
          local list = harpoon:list()
          local item = list.config.create_list_item(list.config)
          local list_item, index = list:get_by_value(item.value)

          local filepath = vim.api.nvim_buf_get_name(0)
          local relpath = require('utils.path').get_relative_path(filepath, vim.fn.getcwd())

          if list_item then
            Notifier.warn({
              { 'Already in list: ', 'Normal' },
              { relpath, 'NotifyWARNTitle' },
              { '\nIndex: ', 'Normal' },
              { tostring(index), 'NotifyWARNTitle' },
              { ', Total: ', 'Normal' },
              { tostring(list:length()), 'NotifyWARNTitle' },
            }, { title = 'harpoon' })
          else
            list:add(item)
            local _, new_index = list:get_by_value(item.value)
            Notifier.info({
              { 'Added ', 'Normal' },
              { relpath, 'NotifyWARNTitle' },
              { '\nIndex: ', 'Normal' },
              { tostring(new_index), 'NotifyWARNTitle' },
              { ', Total: ', 'Normal' },
              { tostring(list:length()), 'NotifyWARNTitle' },
            }, { title = 'harpoon' })
          end
        end,
        desc = 'Harpoon Current File',
      },
      {
        '<leader>fp',
        function()
          require('plugins.ui.snacks.pickers.harpoon')()
        end,
        desc = 'Harpoon: Quick Menu',
      },
    }

    for i = 1, 5 do
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
}
