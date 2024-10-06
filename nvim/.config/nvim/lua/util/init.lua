local CommonUtil = require("util.common")

---@class util: util.common
---@field git util.git
---@field toggle util.toggle
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
