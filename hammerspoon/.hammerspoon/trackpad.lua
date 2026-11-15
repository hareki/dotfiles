-- The one tap on trackpad gesture events, shared by every gesture binding.
--
-- Reading an event's touches or its specific type converts it to an NSEvent, and only the first
-- conversion reports which fingers just landed or lifted: later ones show new fingers as
-- stationary and drop lifted ones. So this tap reads the touches first, then the type, and hands
-- both to every handler. Another gesture tap would break that, since a tap created later sees
-- each event first.
local M = {}

---@alias trackpad.handler fun(gesture: integer, touches: table[]): boolean?

---@type trackpad.handler[]
local handlers = {}

--- Calls `handler` with each gesture event's specific type and touches. Returning true deletes
--- the event.
---@param handler trackpad.handler
function M.on_gesture(handler)
  table.insert(handlers, handler)
end

-- Kept on the module, which package.loaded holds: Hammerspoon stops a collected tap
M.tap = hs.eventtap
  .new({ hs.eventtap.event.types.gesture }, function(event)
    local touches = event:getTouches()
    local gesture = event:getType(true)
    local delete = false
    for _, handler in ipairs(handlers) do
      delete = handler(gesture, touches) or delete
    end
    return delete
  end)
  :start()

return M
