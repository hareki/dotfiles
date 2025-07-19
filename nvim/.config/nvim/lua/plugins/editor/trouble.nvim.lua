return {
  'folke/trouble.nvim',
  cmd = { 'Trouble' },
  opts = function()
    local preview_cols, preview_rows = Util.size.computed_size(Const.size.side_preview.md)
    local panel_cols, _ = Util.size.computed_size(Const.size.side_panel.md)
    local preview_width_offset = panel_cols + preview_cols + 3
    local preview_height_offset = math.floor((vim.opt.lines:get() - preview_rows) / 2) - 1

    Util.highlights({
      TroubleNormal = { link = 'NormalFloat' },
    })

    return {
      -- Prevent trouble from refreshing every time the curosr position changes
      auto_refresh = false,
      win = { position = 'right', size = panel_cols },
      preview = {
        type = 'float',
        relative = 'win',
        border = 'rounded',
        title = ' ' .. Const.PREVIEW_TITLE .. ' ',
        title_pos = 'center',
        position = { preview_height_offset, -preview_width_offset },
        size = {
          width = preview_cols,
          height = preview_rows,
        },
        zindex = 200,
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
