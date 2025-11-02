local M = {}

---@param fn fun()
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, err = pcall(fn)
  vim.o.eventignore = ei
  if not ok then
    error(err, 0)
  end
end

---@param ... table[]
---@return table
function M.list_extend(...)
  local result = {}
  for _, keymap_array in ipairs({ ... }) do
    if keymap_array then
      vim.list_extend(result, keymap_array)
    end
  end
  return result
end

---@param win integer|nil
---@return boolean
function M.focus_win(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  M.noautocmd(function()
    vim.api.nvim_set_current_win(win)
  end)

  return true
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
