-- The one tap on trackpad gesture events, shared by every gesture binding.
--
-- Reading an event's touches or its specific type converts it to an NSEvent, and only the first
-- conversion reports which fingers just landed or lifted: later ones show new fingers as
-- stationary and drop lifted ones. So this tap reads the touches first, then the type, and hands
-- the touches to every handler of that type. Another gesture tap would break that, since a tap
-- created later sees each event first.
local M = {}

---@alias trackpad.handler fun(touches: table[]): boolean?

---@type table<integer, trackpad.handler[]>
local handlers = {}

--- Calls `handler` with the touches of each gesture event whose specific type is `gesture`, one
--- of `hs.eventtap.event.types`. Returning true deletes the event.
---@param gesture integer
---@param handler trackpad.handler
function M.on_gesture(gesture, handler)
  handlers[gesture] = handlers[gesture] or {}
  table.insert(handlers[gesture], handler)
end

-- Kept on the module, which package.loaded holds: Hammerspoon stops a collected tap
M.tap = hs.eventtap
  .new({ hs.eventtap.event.types.gesture }, function(event)
    local touches = event:getTouches()
    local of_type = handlers[event:getType(true)]
    if not of_type then
      return false
    end
    local delete = false
    for _, handler in ipairs(of_type) do
      delete = handler(touches) or delete
    end
    return delete
  end)
  :start()

return M
