---@class CommonUtil
local M = {}

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

M.aucmd = vim.api.nvim_create_autocmd

M.map = vim.keymap.set
M.unmap = vim.keymap.del

--- @param group string
--- @param style table
M.hl = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- @param t1 table
--- @param t2 table
M.mergeTables = function(t1, t2)
  -- Iterate through each key-value pair in the second table
  for k, v in pairs(t2) do
    -- If the value is a table and the key also exists in t1 as a table, merge recursively
    if type(v) == "table" and type(t1[k]) == "table" then
      M.mergeTables(t1[k], v)
    else
      -- Otherwise, overwrite or add the value from t2 to t1
      t1[k] = v
    end
  end
end

M.get_selected_highlights = function(configs, color)
  local result = {}

  local visible_highlights = {
    bold = true,
  }

  local diagnostic_selected_highlights = {
    italic = false,
    sp = color,
  }

  local selected_highlights = {
    italic = false,
    sp = color,
  }

  for _, label in ipairs(configs["diagnostic_selected"]) do
    result[label .. "_visible"] = visible_highlights
    result[label .. "_selected"] = selected_highlights
    result[label .. "_diagnostic_selected"] = diagnostic_selected_highlights
  end

  for _, label in ipairs(configs["diagnostic"]) do
    result[label .. "_visible"] = visible_highlights
    result[label .. "_selected"] = selected_highlights
  end

  return result
end

M.remove_lualine_component = function(name, tbl)
  -- Iterate through the table in reverse to avoid issues when removing elements (skipping elements)
  for i = #tbl, 1, -1 do
    if tbl[i][1] == name then
      table.remove(tbl, i)
    end
  end
end

return M
