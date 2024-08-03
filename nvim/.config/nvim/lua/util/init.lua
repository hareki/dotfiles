local CommonUtil = require("util.common")

---@class util: CommonUtil
---@field inspect util.inspect
---@field toggle_notify util.toggle_notify
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if CommonUtil[k] then
      return CommonUtil[k]
    end

    -- @diagnostic disable-next-line: no-unknown
    t[k] = require("util." .. k)
    return t[k]
  end,
})

return M
