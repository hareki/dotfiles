-- The one gesture event tap. Only an event's first conversion reports landed and lifted fingers,
-- so this reads touches before the type; a second tap would see each event first and hide them.
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
