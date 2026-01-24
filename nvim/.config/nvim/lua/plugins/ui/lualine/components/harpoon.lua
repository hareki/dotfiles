---@class Lualine.Components.Harpoon
local M = {}

--- Get all harpoon indices that have files, with current buffer's index wrapped in brackets
---@return string|nil formatted as "1 [3] 4" or nil if harpoon list is empty
function M.status()
  local harpoon = require('harpoon')
  local list = harpoon:list()
  local length = list:length()

  if length == 0 then
    return nil
  end

  local current_item = list.config.create_list_item(list.config)
  local _, current_index = list:get_by_value(current_item.value)

  local indices = {}
  for i = 1, length do
    local item = list:get(i)
    if item then
      if i == current_index then
        table.insert(indices, '[' .. i .. ']')
      else
        table.insert(indices, tostring(i))
      end
    end
  end

  if #indices == 0 then
    return nil
  end

  return table.concat(indices, ' ')
end

---Check if there are any harpooned files
---@return boolean has_harpooned_files True if there are any files in the harpoon list
function M.has_items()
  local harpoon = require('harpoon')
  local list = harpoon:list()
  local length = list:length()

  if length == 0 then
    return false
  end

  for i = 1, length do
    local item = list:get(i)
    if item then
      return true
    end
  end

  return false
end

return M
