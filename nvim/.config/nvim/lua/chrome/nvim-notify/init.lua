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

        on_open = function(win, record)
          vim.api.nvim_win_set_config(win, { zindex = Conf.zindex.NOTIFY })
          notify_utils.dress(win, record)
          notify_utils.fit(win)
        end,

        render = function(bufnr, notif, hl)
          local title = notif.title[1]
          if notif.duplicates then
            title = string.format('%s (x%d)', title, #notif.duplicates)
          end
          title = string.format(' %s %s ', notif.icon, title)

          -- Set title on first notification (see `on_open` callback)
          vim.b[bufnr][notify_utils.TITLE_KEY] = { { title, hl.title } }

          -- Body coloring comes from the window's winhl (Normal:Notify*Body), not extmarks; a
          -- Notifier message's own highlights come from the render it carries, which calls this one
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)

          -- A duplicate re-renders into the window of the toast it repeats, which takes its title
          -- here. nvim-notify then sizes the toast to the message again, once this render has
          -- returned, so the fit comes after that
          for _, toast in ipairs(vim.fn.win_findbuf(bufnr)) do
            notify_utils.dress(toast, notif)
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(toast) then
                notify_utils.fit(toast)
              end
            end)
          end
        end,
      }
    end,
  },
}
