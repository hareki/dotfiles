--- @class features.diagnostics.trouble.utils
local M = {}

--- Jump to the next/previous item of the open trouble view, else of the quickfix list
--- @param direction 'next' | 'prev'
function M.jump(direction)
  local trouble = require('trouble')

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

--- Move focus from the trouble list into its preview float, with buffer-local keys to get back
function M.toggle_focus()
  local preview_manager = require('trouble.view.preview')
  local preview = preview_manager.preview

  if not preview_manager.is_open() or not preview then
    return
  end

  local trouble_win = vim.api.nvim_get_current_win()
  local common = require('utils.common')
  local map = common.buf_mapper(preview.buf)

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

return M
