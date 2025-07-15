local CommonUtil = require('utils.common')

---@class util: util.common
---@field buffer util.buffer
---@field git util.git
---@field notify util.notify
---@field telescope util.telescope
---@field size util.size
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if CommonUtil[k] then
      return CommonUtil[k]
    end

    t[k] = require('utils.' .. k)
    return t[k]
  end,
})

return M
