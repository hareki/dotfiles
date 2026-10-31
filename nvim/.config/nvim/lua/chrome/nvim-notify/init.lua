local prefix = 'Notification: '

return {
  UI.which_key({
    rules = {
      {
        pattern = prefix:lower() .. 'show history',
        icon = Conf.icons.editor.SHOW_NOTIFICATION,
        color = 'yellow',
      },
      { pattern = 'notification', icon = Conf.icons.editor.NOTIFICATION, color = 'yellow' },
    },
  }),

  {
    -- noice.nvim will automatically load this plugin when needed
    'rcarriga/nvim-notify',
    keys = {
      {
        '<leader>fn',
        function()
          -- May use `Snacks.picker.noice()` as well
          local notify_utils = require('chrome.nvim-notify.utils')
          notify_utils.show_picker()
        end,
        desc = prefix .. 'Show History',
      },
    },

    opts = function()
      local title_key = 'notify_title_with_hl'

      return {
        stages = 'static',
        timeout = 2000,
        fps = 10, -- The static stage animates nothing: this only polls the timeouts

        max_height = UI.layout.inline_max_height,
        max_width = UI.layout.inline_max_width,

        on_open = function(win)
          local buf = vim.api.nvim_win_get_buf(win)
          local title = vim.b[buf][title_key]

          vim.api.nvim_win_set_config(win, {
            -- Above the Snacks terminals (100); an equal zindex hides it behind a focused one
            zindex = 101,
            title = title,
            title_pos = 'center',
          })
        end,

        render = function(bufnr, notif, hl)
          local title = notif.title[1]
          if notif.duplicates then
            title = string.format('%s (x%d)', title, #notif.duplicates)
          end
          title = string.format(' %s %s ', notif.icon, title)

          local title_with_hl = { { title, hl.title } }

          -- Set title on first notification (see `on_open` callback)
          vim.b[bufnr][title_key] = title_with_hl

          -- Set title on duplicate notifications
          for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
            vim.api.nvim_win_set_config(win, {
              title = title_with_hl,
              title_pos = 'center',
            })
          end

          -- Body coloring comes from the window's winhl (Normal:Notify*Body), not extmarks
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
        end,
      }
    end,
  },
}
