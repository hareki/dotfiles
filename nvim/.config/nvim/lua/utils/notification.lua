-- TODO: implement this when we have a notification system
---@class util.notification.
local M = {}

--- @param message string
--- @return nil
function M.info(message)
    print("INFO: " .. message)
end

--- @param message string
--- @return nil
function M.warn(message)
    print("WARN: " .. message)
end

--- @param message string
--- @return nil
function M.error(message)
    print("ERROR: " .. message)
end

return M
