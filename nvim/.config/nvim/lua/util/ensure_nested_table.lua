---@class util.ensure_nested_table
local M = {}

--- Ensures that the nested tables exist in the given table.
--- @param t table The table to operate on.
--- @vararg string The keys to ensure nested tables for.
--- @return  table nested_table the innermost table that was ensured.
function M.run(t, ...)
  local keys = { ... }
  for _, key in ipairs(keys) do
    if t[key] == nil then
      t[key] = {}
    end
    t = t[key]
  end
  return t
end

return M
