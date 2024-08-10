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

M.get_initial_path = function()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(tostring(first_arg), ":p")

  return initial_path
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
