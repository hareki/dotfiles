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

return M
