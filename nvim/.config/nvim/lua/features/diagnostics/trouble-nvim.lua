--- @module 'trouble'
local trouble = Defer.on_exported_call('trouble')

return {
  UI.catppuccin(function()
    return {
      TroubleNormal = { link = 'NormalFloat' },
      TroublePreview = { link = 'Search' },
      TroubleIconDirectory = { link = 'Directory' },
    }
  end, 'trouble.nvim'),

  {
    'hareki/trouble.nvim',
    cmd = { 'Trouble' },
    keys = {
      {
        '[q',
        function()
          if trouble.is_open() then
            --- @diagnostic disable-next-line: missing-parameter, missing-fields
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
          if trouble.is_open() then
            --- @diagnostic disable-next-line: missing-parameter, missing-fields
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
    },

    opts = function()
      local preview_cols, preview_rows = UI.layout.side_size('side_preview', 'md')
      local panel_cols, _ = UI.layout.side_size('side_panel', 'md')
      local preview_width_offset = panel_cols + preview_cols + 3

      local function toggle_focus()
        local preview_manager = require('trouble.view.preview')
        local preview = preview_manager.preview

        if not preview_manager.is_open() or not preview then
          return
        end

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = preview.buf, desc = desc })
        end

        local trouble_win = vim.api.nvim_get_current_win()

        local common = require('utils.common')
        common.focus_win(preview.win)

        map('n', '<Tab>', function()
          if vim.api.nvim_win_is_valid(trouble_win) then
            common.focus_win(trouble_win)
          end
        end, 'Focus Trouble Window')

        map('n', '<CR>', function()
          local trouble_view = require('trouble.view')
          local first_view = trouble_view.get({ open = true })[1]
          if first_view and preview.item then
            first_view.view:jump(preview.item)
          end
        end, 'Jump to Item')

        map('n', 'q', function()
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
          folder_closed = Conf.icons.file_tree.FOLDER,
          folder_open = Conf.icons.file_tree.FOLDER_EMPTY_OPEN,
        },

        preview = {
          type = 'float',
          relative = 'win',
          border = 'rounded',
          title = Conf.picker.PREVIEW_TITLE,
          title_pos = 'center',
          -- Fractional row: trouble resolves <=1 values against the parent on
          -- every float open, so vertical centering survives terminal resizes
          -- (an absolute row from vim.o.lines would freeze at plugin load).
          -- The col offset is panel-anchored, so it needs no recomputation
          position = { 0.5, -preview_width_offset },
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
