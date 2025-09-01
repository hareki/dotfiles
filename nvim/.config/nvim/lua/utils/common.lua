local M = {}

---@param fn function
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  fn()
  vim.o.eventignore = ei
end

---comment
---@param ... table[]
---@return table
function M.list_extend(...)
  local result = {}
  for _, keymap_array in ipairs({ ... }) do
    for _, keymap in ipairs(keymap_array) do
      table.insert(result, keymap)
    end
  end
  return result
end

function M.count_string_keys(t)
  local n = 0
  for k in pairs(t) do
    if type(k) == 'string' then
      n = n + 1
    end
  end
  return n
end

return M
