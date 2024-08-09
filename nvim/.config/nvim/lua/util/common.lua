---@class CommonUtil
local M = {}

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

M.aucmd = vim.api.nvim_create_autocmd

M.map = vim.keymap.set
M.unmap = vim.keymap.del

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

return M
