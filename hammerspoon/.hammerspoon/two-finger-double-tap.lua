-- Two-finger double tap => Cmd+W.
--
-- macOS only recognizes a two-finger double tap while Trackpad > Scroll & Zoom > Smart zoom is
-- on, and reports it as a smartMagnify event. That recognizer is also what holds back a
-- two-finger tap's right click until no second tap follows, so the double tap never opens a
-- context menu. The handler deletes the event, so no app ever zooms on it.
local trackpad = require('trackpad')

local types = hs.eventtap.event.types

local smart_zoom = hs.execute(
  'defaults read com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture 2>/dev/null'
)
if tonumber(smart_zoom) == 0 then
  hs.alert.show('Smart zoom is off in Trackpad settings: a two-finger double tap cannot close', 10)
end

trackpad.on_gesture(types.smartMagnify, function()
  -- keyStroke sleeps its delay (200ms by default) between key down and up, stalling the tap
  hs.eventtap.keyStroke({ 'cmd' }, 'w', 0)
  return true
end)
