local M = {}

--- @param prefix string
local function generate_formatter(prefix)
  ---@param tab_id? integer
  return function(tab_id)
    return string.format('%s:%d', prefix, tab_id or vim.api.nvim_get_current_tabpage())
  end
end

local name_formatter = {
  default = generate_formatter('tab'),
  terminal = generate_formatter('terminal tab'),
  diffview = generate_formatter('diffview tab'),
}

---@param tab_id? integer
M.get_tab_name = function(tab_id)
  local name = nil
  local buf = vim.api.nvim_get_current_buf()
  local is_diffview = function()
    if not package.loaded['diffview'] then
      return false
    end

    return require('diffview.lib').get_current_view()
  end

  if vim.bo[buf].buftype == 'terminal' then
    name = name_formatter.terminal(tab_id)
  elseif is_diffview() then
    name = name_formatter.diffview(tab_id)
  else
    name = name_formatter.default(tab_id)
  end

  return name
end

function M.lualine()
  local existing_name = vim.t.tab_name

  if not existing_name then
    vim.t.tab_name = M.get_tab_name()
    return vim.t.tab_name
  end

  return existing_name
end

return M
