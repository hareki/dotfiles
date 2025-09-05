local M = {}

-- Copy of:
-- https://github.com/Bekaboo/dropbar.nvim/blob/a0ad7e24e9dfde6f0b11f6a436f56aeceaf58e9b/lua/dropbar/configs.lua#L265
-- And disable terminal buffers
---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
function M.enable(buf, win, _)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    return false
  end

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

  return vim.bo[buf].ft == 'markdown'
    or pcall(vim.treesitter.get_parser, buf)
    or not vim.tbl_isempty(vim.lsp.get_clients({
      bufnr = buf,
      method = vim.lsp.protocol.Methods.textDocument_documentSymbol,
    }))
end

return M
