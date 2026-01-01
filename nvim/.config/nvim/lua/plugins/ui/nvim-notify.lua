return {
  -- noice.nvim will automatically load this plugin when needed
  'rcarriga/nvim-notify',
  keys = {
    {
      '<leader>ud',
      function()
        require('notify').dismiss({ silent = true, pending = true })
      end,
      desc = 'Dismiss All Notifications',
    },
    {
      '<leader>un',
      function()
        local notify = require('telescope').extensions.notify.notify
        local preview_title = require('configs.picker').telescope_preview_title
        local new_buffer_previewer = require('telescope.previewers').new_buffer_previewer

        -- May use `:Telescope noice` as well
        notify({
          results_title = '',
          preview_title = preview_title,
          previewer = new_buffer_previewer({
            define_preview = function(self, entry, status)
              local notification = entry.value
              local max_width = vim.api.nvim_win_get_config(status.preview_win).width or 1
              local buf = self.state.bufnr

              require('notify').open(notification, {
                buffer = buf,
                max_width = max_width,
              })

              vim.schedule(function()
                vim.wo[status.preview_win].wrap = true
                vim.bo[buf].filetype = 'markdown'
                require('render-markdown').render({
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
      desc = 'Show Notification History',
    },
  },
  opts = function()
    local title_key = 'notify_title_with_hl'
    local max_size = require('configs.size').inline_popup.max_height

    return {
      stages = 'static',
      timeout = 4000,
      merge_duplicates = true,
      max_height = function()
        return math.floor(vim.o.lines * max_size)
      end,
      max_width = function()
        return math.floor(vim.o.columns * max_size)
      end,

      render = function(bufnr, notif, hl, _)
        local base = require('notify.render.base')
        local ns = base.namespace()

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

        -- Set notification content
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
        vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
          end_line = #notif.message - 1,
          end_col = #notif.message[#notif.message],
          priority = 50,
        })
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
    }
  end,
}
