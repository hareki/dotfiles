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
          require('harpoon'):list():add()
          -- Full path of the current buffer
          local filepath = vim.api.nvim_buf_get_name(0)

          -- local filename = vim.fn.fnamemodify(filepath, ':t')
          local relpath = vim.fn.fnamemodify(filepath, ':.')

          Notifier.info({
            { 'Added ', 'Normal' },
            { relpath, 'NotifyWARNTitle' },
          }, { title = 'harpoon' })
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
