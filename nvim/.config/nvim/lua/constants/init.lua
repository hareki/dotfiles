local CommonConstant = require('constants.common')

---@class constant.common
---@field git constant.git
---@field size constant.size
---@field icons constant.icons
local M = {}

-- setmetatable(M, {
--   __index = function(t, k)
--     t[k] = require('constants.' .. k)
--     return t[k]
--   end,
-- })

setmetatable(M, {
  __index = function(t, k)
    if CommonConstant[k] then
      return CommonConstant[k]
    end

    t[k] = require('constants.' .. k)
    return t[k]
  end,
})

return M
