local prefix = 'Notification: '

--- @module 'notify'
local notify = Defer.on_exported_call('notify')

return {
  UI.which_key({
    specs = { '<leader>u', group = 'Notification' },
    rules = {
      {
        pattern = prefix:lower() .. 'dismiss all',
        icon = Conf.icons.editor.DISMISS_NOTIFICATION,
        color = 'yellow',
      },
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
        '<leader>ud',
        function()
          notify.dismiss({ silent = true, pending = true })
        end,
        desc = prefix .. 'Dismiss All',
      },
      {
        '<leader>un',
        function()
          local telescope = require('telescope')
          local telescope_notify = telescope.extensions.notify.notify
          local preview_title = Conf.picker.TELESCOPE_PREVIEW_TITLE
          local telescope_previewers = require('telescope.previewers')
          local new_buffer_previewer = telescope_previewers.new_buffer_previewer

          -- May use `:Telescope noice` as well
          telescope_notify({
            prompt_title = 'Notifications',
            results_title = '',
            preview_title = preview_title,
            previewer = new_buffer_previewer({
              define_preview = function(self, entry, status)
                local notification = entry.value
                local max_width = vim.api.nvim_win_get_config(status.preview_win).width or 1
                local buf = self.state.bufnr

                notify.open(notification, {
                  buffer = buf,
                  max_width = max_width,
                })

                vim.schedule(function()
                  vim.wo[status.preview_win].wrap = true
                  vim.bo[buf].filetype = 'markdown'
                  local render_markdown = require('render-markdown')
                  render_markdown.render({
                    buf = buf,
                    config = {
                      render_modes = true,
                    },
                  })
                end)
              end,
            }),
          })
        end,
        desc = prefix .. 'Show History',
      },
    },

    opts = function()
      local title_key = 'notify_title_with_hl'
      local max_size = Conf.size.inline_popup.MAX_HEIGHT

      return {
        stages = 'static',
        timeout = 2000,
        merge_duplicates = true,

        max_height = function()
          return math.floor(vim.o.lines * max_size)
        end,
        max_width = function()
          return math.floor(vim.o.columns * max_size)
        end,

        on_open = function(win)
          local buf = vim.api.nvim_win_get_buf(win)
          local title = vim.b[buf][title_key]

          vim.api.nvim_win_set_config(win, {
            zindex = 100,
            title = title,
            title_pos = 'center',
          })
        end,

        render = function(bufnr, notif, hl, _)
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
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_set_config(win, {
                title = title_with_hl,
                title_pos = 'center',
              })
            end
          end

          -- Set notification content; body coloring comes from the window's
          -- winhl (Normal:Notify*Body), no extmark highlighting needed
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
        end,
      }
    end,
  },
}
