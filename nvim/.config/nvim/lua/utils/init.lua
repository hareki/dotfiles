local CommonUtil = require("utils.common")

---@class util: util.common
---@field git util.git
---@field toggle util.toggle
---@field buffer util.buffer
local M = {}

setmetatable(M, {
    __index = function(t, k)
        if CommonUtil[k] then
            return CommonUtil[k]
        end

        print("Loading utils." .. k)

        t[k] = require("utils." .. k)
        return t[k]
    end,
})

return M
