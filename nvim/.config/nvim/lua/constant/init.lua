---@class constant
---@field filetype constant.filetype
---@field git constant.git
---@field telescope constant.telescope
---@field yanky constant.yanky
local M = {}

setmetatable(M, {
  __index = function(t, k)
    -- @diagnostic disable-next-line: no-unknown
    t[k] = require("constant." .. k)
    return t[k]
  end,
})

return M
