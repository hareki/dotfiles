local PREFIX = 'Notification: '

return {
  UI.catppuccin.integration('notify'),
  UI.which_key({
    rules = {
      {
        pattern = PREFIX:lower() .. 'show history',
        icon = Conf.icons.editor.SHOW_NOTIFICATION,
        color = 'yellow',
      },
      { pattern = 'notification', icon = Conf.icons.editor.NOTIFICATION, color = 'yellow' },
    },
  }),

  {
    -- noice.nvim will automatically load this plugin when needed
    'hareki/nvim-notify',
    keys = {
      {
        '<leader>fn',
        function()
          -- May use `Snacks.picker.noice()` as well
          local notify_utils = require('chrome.nvim-notify.utils')
          notify_utils.show_picker()
        end,
        desc = PREFIX .. 'Show History',
      },
    },

    opts = function()
      local notify_utils = require('chrome.nvim-notify.utils')

      return {
        stages = 'static',
        timeout = 2000,
        fps = 10, -- The static stage animates nothing: this only polls the timeouts

        max_height = UI.layout.inline_max_height,
        max_width = UI.layout.inline_max_width,

        on_open = function(win)
          local buf = vim.api.nvim_win_get_buf(win)
          -- None from a notification sent with a render of its own, which never runs the one below
          local title = vim.b[buf][notify_utils.TITLE_KEY]

          vim.api.nvim_win_set_config(win, {
            zindex = Conf.zindex.NOTIFY,
            title = title,
            title_pos = title and 'center' or nil,
          })
          Notifier.paint_window(win)
          Notifier.fit_toast(win, UI.layout.inline_max_width(), UI.layout.inline_max_height())
        end,

        render = function(bufnr, notif, hl)
          local title = notif.title[1]
          if notif.duplicates then
            title = string.format('%s (x%d)', title, #notif.duplicates)
          end
          title = string.format(' %s %s ', notif.icon, title)

          local title_with_hl = { { title, hl.title } }

          -- Set title on first notification (see `on_open` callback)
          vim.b[bufnr][notify_utils.TITLE_KEY] = title_with_hl

          -- Set title on duplicate notifications
          for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
            vim.api.nvim_win_set_config(win, {
              title = title_with_hl,
              title_pos = 'center',
            })
          end

          -- Body coloring comes from the window's winhl (Normal:Notify*Body), not extmarks; a
          -- Notifier message's own highlights come from the render it carries, which calls this one
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
        end,
      }
    end,
  },
}
