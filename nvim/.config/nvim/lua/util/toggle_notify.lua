---@class util.toggle_notify
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.toggle_notify(...)
  end,
})

--- @param feature string
--- @param value number | string
function M.toggle_notify(feature, value)
  local message
  if type(value) == "boolean" then
    if value then
      message = "Enabled " .. feature
    else
      message = "Disabled " .. feature
    end
  elseif type(value) == "number" or type(value) == "string" then
    message = "Set " .. feature .. " to " .. tostring(value)
  else
    error("Unsupported value type: " .. type(value))
  end
  return message
end

return M
