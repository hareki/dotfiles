---@class plugins.ui.dropbar.utils
local M = {}

---Determine if dropbar should be enabled for a buffer/window
---Filters out help files, terminals, and large files (>1MB).
---@param buf integer Buffer number
---@param win integer Window handle
---@param _ table|nil Additional info (unused)
---@return boolean enabled True if dropbar should be enabled
function M.enable(buf, win, _)
  buf = vim._resolve_bufnr(buf)
  local ignored_filetypes = { 'help', 'trouble' }
  local ignored_buftypes = { 'terminal' }

  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_win_is_valid(win)
    or vim.fn.win_gettype(win) ~= ''
    or vim.wo[win].winbar ~= ''
    or vim.list_contains(ignored_filetypes, vim.bo[buf].filetype)
    or vim.list_contains(ignored_buftypes, vim.bo[buf].buftype)
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
