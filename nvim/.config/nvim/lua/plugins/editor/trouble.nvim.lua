return {
  Catppuccin(function()
    return {
      TroubleNormal = { link = 'NormalFloat' },
      TroublePreview = { link = 'Search' },
      TroubleIconDirectory = { link = 'Directory' },
    }
  end),
  {
    'hareki/trouble.nvim',
    cmd = { 'Trouble' },
    keys = function()
      return {
        {
          '[q',
          function()
            local trouble = require('trouble')

            if trouble.is_open() then
              ---@diagnostic disable-next-line: missing-parameter, missing-fields
              trouble.prev({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cprev)
              if not ok then
                Notifier.error(err)
              end
            end
          end,
          desc = 'Previous Trouble/Quickfix Item',
        },

        {
          ']q',
          function()
            local trouble = require('trouble')

            if trouble.is_open() then
              ---@diagnostic disable-next-line: missing-parameter, missing-fields
              trouble.next({ skip_groups = true, jump = true })
            else
              local ok, err = pcall(vim.cmd.cnext)
              if not ok then
                Notifier.error(err)
              end
            end
          end,
          desc = 'Next Trouble/Quickfix Item',
        },
      }
    end,

    opts = function()
      local ui_utils = require('utils.ui')
      local icons = require('configs.icons')
      local size_configs = require('configs.size')
      local picker_config = require('configs.picker')
      local preview_cols, preview_rows = ui_utils.computed_size(size_configs.side_preview.md)
      local panel_cols, _ = ui_utils.computed_size(size_configs.side_panel.md)
      local preview_width_offset = panel_cols + preview_cols + 3
      local preview_height_offset = math.floor((vim.o.lines - preview_rows) / 2) - 1

      local function toggle_focus()
        local previewManager = require('trouble.view.preview')
        local preview = previewManager.preview

        if not previewManager.is_open() or not preview then
          return
        end

        local function map(key, callback, desc)
          vim.keymap.set('n', key, callback, { buffer = preview.buf, desc = desc })
        end

        local trouble_win = vim.api.nvim_get_current_win()

        local common = require('utils.common')
        common.focus_win(preview.win)

        map('<Tab>', function()
          if vim.api.nvim_win_is_valid(trouble_win) then
            common.focus_win(trouble_win)
          end
        end, 'Focus Trouble Window')

        map('<CR>', function()
          local trouble_view = require('trouble.view')
          local first_view = trouble_view.get({ open = true })[1]
          if first_view and preview.item then
            first_view.view:jump(preview.item)
          end
        end, 'Jump to Item')

        map('q', function()
          if vim.api.nvim_win_is_valid(trouble_win) then
            common.focus_win(trouble_win)
          end
          if vim.api.nvim_win_is_valid(preview.win) then
            vim.api.nvim_win_close(preview.win, true)
          end
        end, 'Close Preview')
      end

      return {
        auto_refresh = false,
        win = { position = 'right', size = panel_cols },

        icons = {
          folder_closed = icons.explorer.folder,
          folder_open = icons.explorer.folder_empty_open,
        },

        preview = {
          type = 'float',
          relative = 'win',
          border = 'rounded',
          title = picker_config.preview_title,
          title_pos = 'center',
          position = { preview_height_offset, -preview_width_offset },
          size = {
            width = preview_cols,
            height = preview_rows,
          },
          zindex = 200,

          reuse_loaded_buf = false,
          notify_on_toggle = false,
          close_on_non_item = true,
        },

        keys = {
          ['<Tab>'] = {
            action = toggle_focus,
            desc = 'Toggle Focus Between List and Preview',
          },
          B = 'toggle_preview',
        },
      }
    end,
  },
}
