-- Two-finger double tap => Cmd+W.
--
-- macOS only recognizes a two-finger double tap while Trackpad > Scroll & Zoom > Smart zoom is
-- on, and reports it as a smartMagnify event. That recognizer is also what holds back a
-- two-finger tap's right click until no second tap follows, so the double tap never opens a
-- context menu. The tap deletes the event, so no app ever zooms on it.
local types = hs.eventtap.event.types

local smart_zoom = hs.execute(
  'defaults read com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture 2>/dev/null'
)
if tonumber(smart_zoom) == 0 then
  hs.alert.show('Smart zoom is off in Trackpad settings: a two-finger double tap cannot close', 10)
end

local tap = hs.eventtap.new({ types.gesture }, function(event)
  if event:getType(true) ~= types.smartMagnify then
    return false
  end
  -- keyStroke sleeps its delay (200ms by default) between key down and up, stalling the callback
  hs.eventtap.keyStroke({ 'cmd' }, 'w', 0)
  return true
end)

-- Returned so package.loaded keeps the tap alive: Hammerspoon stops a collected watcher
return tap:start()
