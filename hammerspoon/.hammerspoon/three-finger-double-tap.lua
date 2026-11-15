-- Three-finger double tap => Cmd+Shift+T.
--
-- macOS has no recognizer for this one (Smart zoom only knows two fingers), so this reads the raw
-- trackpad touches. A tap is one contact, from the first finger down to the last one up, that
-- peaks at exactly three fingers, stays short and barely moves. Nothing is swallowed: macOS does
-- nothing on a three-finger tap while Look up is not set to "Tap with three fingers".
local trackpad = require('trackpad')

local types = hs.eventtap.event.types

local FINGERS = 3
local MAX_TAP_SECONDS = 0.3
-- In fractions of the trackpad's width and height
local MAX_TRAVEL = 0.04
-- The longest pause between the two taps
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
    local origin = contact.origins[finger.identity]
    if not origin then
      contact.origins[finger.identity] = position
    elseif
      math.abs(position.x - origin.x) > MAX_TRAVEL or math.abs(position.y - origin.y) > MAX_TRAVEL
    then
      contact.disqualified = true
    end
    if finger.phase == 'cancelled' then
      contact.disqualified = true
    end
    if finger.touching then
      down = down + 1
    end
  end
  contact.peak = math.max(contact.peak, down)

  if down == 0 then
    local ended = contact
    contact = nil
    on_contact_end(ended, now)
  end
end

trackpad.on_gesture(function(gesture, touches)
  if gesture == types.gesture then
    on_touches(touches, hs.timer.absoluteTime() / 1e9)
  end
end)
