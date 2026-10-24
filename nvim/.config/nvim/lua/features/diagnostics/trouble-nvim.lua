--- @module 'trouble'
local trouble = Defer.on_exported_call('trouble')

--- Jump to the next/previous item of the open trouble view, else of the quickfix list
--- @param direction 'next' | 'prev'
local function jump(direction)
  return function()
    if trouble.is_open() then
      --- @diagnostic disable-next-line: missing-parameter, missing-fields
      trouble[direction]({ jump = true })
    else
      local ok, err = pcall(vim.cmd[direction == 'next' and 'cnext' or 'cprev'])
      if not ok then
        Notifier.error(err)
      end
    end
  end
end

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
      { '[q', jump('prev'), desc = 'Previous Trouble/Quickfix Item' },
      { ']q', jump('next'), desc = 'Next Trouble/Quickfix Item' },
    },

    opts = function()
      local side_preview = UI.layout.side_preview()
      local panel_cols = UI.layout.side_size('side_panel', 'md')

      local function toggle_focus()
        local preview_manager = require('trouble.view.preview')
        local preview = preview_manager.preview

        if not preview_manager.is_open() or not preview then
          return
        end

        local trouble_win = vim.api.nvim_get_current_win()
        local common = require('utils.common')
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = preview.buf, desc = desc })
        end

        common.focus_win(preview.win)

        map('n', '<Tab>', function()
          common.focus_win(trouble_win)
        end, 'Focus Trouble Window')

        map('n', '<CR>', function()
          local trouble_view = require('trouble.view')
          local first_view = trouble_view.get({ open = true })[1]
          if first_view and preview.item then
            first_view.view:jump(preview.item)
          end
        end, 'Jump to Item')

        map('n', 'q', function()
          common.focus_win(trouble_win)
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
          -- Fractional row: trouble resolves it against the parent on every open, so centering
          -- survives resizes; a negative col counts from the panel's right edge, hence the shift
          position = { 0.5, side_preview.col - panel_cols },
          size = {
            width = side_preview.width,
            height = side_preview.height,
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
