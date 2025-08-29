local M = {}

function M.current_tab_index()
  return vim.api.nvim_tabpage_get_number(vim.api.nvim_get_current_tabpage())
end

function M.lualine()
  local name = vim.t.tab_name
  if not name or name == '' then
    name = 'tab ' .. M.current_tab_index()
  end
  return name
end

return M
