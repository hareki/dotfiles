--- @class chrome.lualine.components.harpoon
local M = {}

--- @class chrome.lualine.components.harpoon.Cache
--- @field buf integer
--- @field length integer
--- @field text string | nil
local cache = {
  buf = -1,
  length = -1,
  text = nil,
}

--- Drop the cached text. Called from harpoon's extension events (see the spec's
--- `config`) for mutations the (buf, length) key can't detect, e.g. replace_at
--- or a same-length menu-save reorder.
--- @return nil
function M.invalidate()
  cache.buf = -1
  cache.length = -1
  cache.text = nil
end

--- Compute (or return cached) harpoon indices text for the current buffer.
--- The statusline re-evaluates on every redraw, so building the list item
--- (plenary path normalization + cwd) each time is wasted work; cache by
--- (current buffer, list length) and let BufEnter-driven redraws re-key it.
--- @return string | nil formatted as "1 [3] 4" or nil if harpoon list is empty
local function compute()
  local harpoon = require('harpoon')
  local list = harpoon:list()
  local length = list:length()
  local buf = vim.api.nvim_get_current_buf()

  if cache.buf == buf and cache.length == length then
    return cache.text
  end

  local text = nil

  if length > 0 then
    local current_item = list.config.create_list_item(list.config)
    local _, current_index = list:get_by_value(current_item.value)

    local indices = {}
    for i = 1, length do
      local item = list:get(i)
      if item then
        if i == current_index then
          indices[#indices + 1] = '[' .. i .. ']'
        else
          indices[#indices + 1] = tostring(i)
        end
      end
    end

    if #indices > 0 then
      text = table.concat(indices, ' ')
    end
  end

  cache.buf = buf
  cache.length = length
  cache.text = text

  return text
end

--- Get all harpoon indices that have files, with current buffer's index wrapped in brackets
--- @return string | nil formatted as "1 [3] 4" or nil if harpoon list is empty
function M.get()
  return compute()
end

--- Check if there are any harpooned files
--- @return boolean has_harpooned_files True if there are any files in the harpoon list
function M.cond()
  return compute() ~= nil
end

M.icon = Conf.icons.tools.PIN

return M
