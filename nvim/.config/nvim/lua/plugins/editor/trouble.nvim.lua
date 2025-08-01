return {
  'hareki/trouble.nvim',
  cmd = { 'Trouble' },
  opts = function()
    local size_utils = require('utils.size')
    local size_configs = require('configs.size')
    local preview_cols, preview_rows = size_utils.computed_size(size_configs.side_preview.md)
    local panel_cols, _ = size_utils.computed_size(size_configs.side_panel.md)
    local preview_width_offset = panel_cols + preview_cols + 3
    local preview_height_offset = math.floor((vim.opt.lines:get() - preview_rows) / 2) - 1

    require('utils.ui').set_highlights({
      TroubleNormal = { link = 'NormalFloat' },
      TroublePreview = { link = 'Search' },
    })

    local function toggle_focus()
      local previewManager = require('trouble.view.preview')
      local preview = previewManager.preview

      if not previewManager.is_open() then
        return
      end

      local function set_preview_keymap(key, callback)
        vim.keymap.set('n', key, callback, { buffer = preview.buf })
      end

      local trouble_win = vim.api.nvim_get_current_win()

      vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', preview.win))

      set_preview_keymap('<Tab>', function()
        vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', trouble_win))
      end)

      set_preview_keymap('<CR>', function()
        local View = require('trouble.view')
        local first_view = View.get({ open = true })[1]
        if first_view and preview.item then
          first_view.view:jump(preview.item)
        end
      end)

      set_preview_keymap('q', function()
        vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', trouble_win))
        vim.api.nvim_win_close(preview.win, true)
      end)
    end

    return {
      auto_refresh = false,
      win = { position = 'right', size = panel_cols },

      preview = {
        type = 'float',
        relative = 'win',
        border = 'rounded',
        title = ' ' .. require('configs.common').PREVIEW_TITLE .. ' ',
        title_pos = 'center',
        position = { preview_height_offset, -preview_width_offset },
        size = {
          width = preview_cols,
          height = preview_rows,
        },
        zindex = 200,
      },

      keys = {
        ['<tab>'] = {
          action = toggle_focus,
          desc = 'Toggle focus between list & preview',
        },
        B = 'toggle_preview',
      },
    }
  end,
  keys = {
    {
      '[q',
      function()
        if require('trouble').is_open() then
          require('trouble').prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = 'Previous Trouble/Quickfix Item',
    },
    {
      ']q',
      function()
        if require('trouble').is_open() then
          require('trouble').next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = 'Next Trouble/Quickfix Item',
    },
  },
}
