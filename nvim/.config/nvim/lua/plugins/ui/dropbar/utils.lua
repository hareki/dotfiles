---@class plugins.ui.dropbar.utils
local M = {}

---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
function M.enable(buf, win, _)
  buf = vim._resolve_bufnr(buf)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_win_is_valid(win)
    or vim.fn.win_gettype(win) ~= ''
    or vim.wo[win].winbar ~= ''
    or vim.bo[buf].ft == 'help'
  then
    return false
  end

  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  if stat and stat.size > 1024 * 1024 then
    return false
  end

  return true
end

return M
