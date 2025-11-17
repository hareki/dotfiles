local M = {}
function M.have_status_line()
  return vim.env.NVIM_NO_STATUS_LINE == nil
end

return M
