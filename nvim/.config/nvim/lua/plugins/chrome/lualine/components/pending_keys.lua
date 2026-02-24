---@class plugins.chrome.lualine.components.pending_keys
local M = {}

--- Debounce state — prevents unnecessary flash of pending keys by
--- suppressing render until the keys have persisted beyond `DURATION`.
local _debounce = {
  ---@type integer ms threshold
  DURATION = 10,
  ---@type integer? timestamp (ms) when pending keys first appeared
  start_ms = nil,
  ---@type uv.uv_timer_t?
  timer = nil,
}

-- Called via `%{v:lua...}` on every statusline redraw, bypassing lualine's
-- refresh timer so count prefixes (e.g. "14" in "14j") appear immediately
-- once they've persisted beyond the debounce threshold.
---@private
---@return string
function M._render()
  local result = vim.api.nvim_eval_statusline('%S', {})

  if result.str == '' then
    _debounce.start_ms = nil
    if _debounce.timer then
      pcall(_debounce.timer.stop, _debounce.timer)
      pcall(_debounce.timer.close, _debounce.timer)
      _debounce.timer = nil
    end
    return ''
  end

  if not _debounce.start_ms then
    _debounce.start_ms = vim.uv.now()
    _debounce.timer = vim.uv.new_timer()

    if _debounce.timer then
      _debounce.timer:start(_debounce.DURATION, 0, function()
        vim.schedule(function()
          vim.cmd.redrawstatus()
        end)
      end)
    end
    return ''
  end

  if vim.uv.now() - _debounce.start_ms < _debounce.DURATION then
    return ''
  end

  return Icons.misc.pending_keys .. ' ' .. result.str
end

function M.get()
  return "%{v:lua.require'plugins.chrome.lualine.components.pending_keys'._render()}"
end

return M
