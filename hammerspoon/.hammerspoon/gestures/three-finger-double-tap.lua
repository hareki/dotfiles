-- Three-finger double tap => Cmd+Shift+T. macOS has no recognizer for it, so this reads the raw
-- touches: a tap is one contact that peaks at three fingers, stays short and barely moves.
local trackpad = require('gestures.trackpad')

local types = hs.eventtap.event.types

local FINGERS = 3
local MAX_TAP_SECONDS = 0.3
-- In fractions of the trackpad's width and height
local MAX_TRAVEL = 0.04
local max_gap_seconds = hs.eventtap.doubleClickInterval()

local contact
local lone_tap_ended

local function on_contact_end(ended, now)
  local is_tap = ended.peak == FINGERS
    and not ended.disqualified
    and now - ended.started <= MAX_TAP_SECONDS
  if is_tap and lone_tap_ended and ended.started - lone_tap_ended <= max_gap_seconds then
    lone_tap_ended = nil
    hs.eventtap.keyStroke({ 'cmd', 'shift' }, 't', 0)
  else
    lone_tap_ended = is_tap and now or nil
  end
end

local function on_touches(touches, now)
  local fingers = {}
  for _, touch in ipairs(touches) do
    if touch.type == 'indirect' and not touch.resting then
      table.insert(fingers, touch)
    end
  end
  if #fingers == 0 then
    return
  end

  contact = contact or { started = now, peak = 0, origins = {} }
  local down = 0
  for _, finger in ipairs(fingers) do
    local position = finger.normalizedPosition
    local origin = contact.origins[finger.identity] or position
    contact.origins[finger.identity] = origin
    if
      finger.phase == 'cancelled'
      or math.abs(position.x - origin.x) > MAX_TRAVEL
      or math.abs(position.y - origin.y) > MAX_TRAVEL
    then
      contact.disqualified = true
    end
    if finger.touching then
      down = down + 1
    end
  end
  contact.peak = math.max(contact.peak, down)

  if down == 0 then
    on_contact_end(contact, now)
    contact = nil
  end
end

trackpad.on_gesture(types.gesture, function(touches)
  on_touches(touches, hs.timer.absoluteTime() / 1e9)
end)
