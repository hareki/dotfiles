--- @class utils.noautocmd
local M = {}

--- Lua's :noautocmd; 'eventignore' comes back even when fn throws
--- @param fn fun()
function M.run(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, err = pcall(fn)
  vim.o.eventignore = ei
  if not ok then
    error(err, 0)
  end
end

return M
