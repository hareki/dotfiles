local M = {}

---@param diagnostic vim.Diagnostic
M.get_pos_key = function(diagnostic)
  return string.format(
    '%d:%d-%d:%d',
    diagnostic.lnum,
    diagnostic.col,
    diagnostic.end_lnum,
    diagnostic.end_col
  )
end

return M
