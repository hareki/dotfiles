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
    vim.notify(message, "warn", { title = "Warning" })
end

--- @param message string
--- @return nil
function M.error(message)
    vim.notify(message, "error", { title = "Error" })
end

return M
