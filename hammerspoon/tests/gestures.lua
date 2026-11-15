-- The trackpad gesture bindings, loaded through init.lua under a fake `hs`.
--
--   nvim --clean -l hammerspoon/tests/gestures.lua
--
-- A fake gesture event reads like a real one: only its first conversion (getTouches() or
-- getType(true)) reports which fingers landed or lifted, while later ones show new fingers as
-- stationary and drop lifted ones, as a real trackpad's events do. Taps see each event newest
-- first, and a deleted event goes no further. So a binding that reads in the wrong order, or a
-- second tap ahead of it, fails here the way it fails live.

local tests = arg[0]:match('(.*)/') or '.'
local config = tests .. '/../.hammerspoon'
package.path = config .. '/?.lua;' .. package.path

local GESTURE, SMART_MAGNIFY, PRESSURE = 29, 32, 34
local MODULES = { 'trackpad', 'two-finger-double-tap', 'three-finger-double-tap' }

local failures = 0
local state

local function check(name, ok)
  if not ok then
    failures = failures + 1
  end
  io.stdout:write((ok and 'PASS ' or 'FAIL ') .. name .. '\n')
end

--- Loads init.lua afresh; `smart_zoom` is what `defaults` prints for the Smart zoom setting.
local function load_config(smart_zoom)
  state = { taps = {}, strokes = {}, alerts = {}, deleted = {}, now = 1000 }
  _G.hs = {
    execute = function(command)
      state.execute = command
      return smart_zoom or '1\n'
    end,
    alert = {
      show = function(message, seconds)
        table.insert(state.alerts, { message = message, seconds = seconds })
      end,
    },
    timer = {
      absoluteTime = function()
        return state.now * 1e9
      end,
    },
    eventtap = {
      event = { types = { gesture = GESTURE, smartMagnify = SMART_MAGNIFY, pressure = PRESSURE } },
      doubleClickInterval = function()
        return 0.5
      end,
      keyStroke = function(modifiers, key, delay)
        table.insert(
          state.strokes,
          { combo = table.concat(modifiers, '+') .. '+' .. key, delay = delay }
        )
      end,
      new = function(mask, callback)
        local tap = { mask = mask, callback = callback }
        function tap:start()
          self.started = true
          return self
        end
        table.insert(state.taps, tap)
        return tap
      end,
    },
  }
  for _, name in ipairs(MODULES) do
    package.loaded[name] = nil
  end
  dofile(config .. '/init.lua')
end

local function hs_touch(touch, phase)
  return {
    identity = tostring(touch.id),
    phase = phase,
    touching = phase ~= 'ended' and phase ~= 'cancelled',
    type = touch.type or 'indirect',
    resting = touch.resting or false,
    normalizedPosition = { x = touch.x, y = touch.y },
  }
end

--- Sends one gesture event whose first conversion reports `touches` ({ id, phase, x, y }).
local function send(ns, touches)
  local first, later = {}, {}
  for _, touch in ipairs(touches) do
    table.insert(first, hs_touch(touch, touch.phase))
    if touch.phase ~= 'ended' and touch.phase ~= 'cancelled' then
      table.insert(later, hs_touch(touch, touch.phase == 'began' and 'stationary' or touch.phase))
    end
  end
  local converted = false
  local function convert()
    local was_first = not converted
    converted = true
    return was_first
  end
  local event = {
    getType = function(_, specific)
      if specific then
        convert()
        return ns
      end
      return GESTURE
    end,
    getTouches = function()
      return convert() and first or later
    end,
  }
  for i = #state.taps, 1, -1 do
    if state.taps[i].callback(event) then
      table.insert(state.deleted, ns)
      return
    end
  end
end

local function pause(seconds)
  state.now = state.now + seconds
end

local next_id = 0

--- One contact: fingers land over two events, hold, then lift together.
local function tap(opts)
  opts = opts or {}
  local fingers, drift = opts.fingers or 3, opts.drift or 0
  local ids = {}
  for i = 1, fingers do
    next_id = next_id + 1
    ids[i] = next_id
  end
  local function all(phase, dx)
    local touches = {}
    for i, id in ipairs(ids) do
      table.insert(touches, { id = id, phase = phase, x = 0.3 + i * 0.1 + dx, y = 0.5 })
    end
    if opts.resting then
      table.insert(
        touches,
        { id = 'thumb', phase = 'stationary', x = 0.1, y = 0.1, resting = true }
      )
    end
    return touches
  end
  send(GESTURE, { { id = ids[1], phase = 'began', x = 0.4, y = 0.5 } })
  pause(0.02)
  local landing = all('began', 0)
  landing[1].phase = 'stationary'
  send(GESTURE, landing)
  if opts.pressure then
    send(PRESSURE, {})
  end
  pause((opts.duration or 0.1) - 0.02)
  send(GESTURE, all('moved', drift))
  send(GESTURE, all(opts.cancel and 'cancelled' or 'ended', drift))
end

local function strokes_after(fn)
  load_config()
  fn()
  return #state.strokes
end

-- The tap

load_config()
local gesture_taps = 0
for _, t in ipairs(state.taps) do
  if t.mask[1] == GESTURE then
    gesture_taps = gesture_taps + 1
  end
end
check('one started tap watches gesture events', gesture_taps == 1 and state.taps[1].started)

-- Two-finger double tap

load_config()
send(SMART_MAGNIFY, {})
check(
  'smart zoom sends cmd+w with no key delay',
  #state.strokes == 1 and state.strokes[1].combo == 'cmd+w' and state.strokes[1].delay == 0
)
check('smart zoom is deleted', #state.deleted == 1 and state.deleted[1] == SMART_MAGNIFY)
tap()
check('touches are not deleted', #state.deleted == 1)
check(
  'reads the trackpad smart zoom setting',
  state.execute:find('TrackpadTwoFingerDoubleTapGesture', 1, true) ~= nil
)
check('no alert while smart zoom is on', #state.alerts == 0)
load_config('0\n')
check('alert when smart zoom is off', #state.alerts == 1 and state.alerts[1].seconds == 10)
load_config('')
check('no alert when the setting is unreadable', #state.alerts == 0)

-- Three-finger double tap

load_config()
tap()
pause(0.2)
tap()
check(
  'double tap sends cmd+shift+t with no key delay',
  #state.strokes == 1 and state.strokes[1].combo == 'cmd+shift+t' and state.strokes[1].delay == 0
)
check('double tap deletes nothing', #state.deleted == 0)
check('single tap does nothing', strokes_after(function()
  tap()
end) == 0)
check('pause past the double-click interval does nothing', strokes_after(function()
  tap()
  pause(0.6)
  tap()
end) == 0)
check('a slow first tap does not count', strokes_after(function()
  tap({ duration = 0.5 })
  pause(0.2)
  tap()
end) == 0)
check('a slow second tap does not count', strokes_after(function()
  tap()
  pause(0.2)
  tap({ duration = 0.5 })
end) == 0)
check('a moving contact (swipe) does not count', strokes_after(function()
  tap()
  pause(0.2)
  tap({ drift = 0.1 })
end) == 0)
check('small drift still counts', strokes_after(function()
  tap({ drift = 0.02 })
  pause(0.2)
  tap({ drift = 0.02 })
end) == 1)
check('two-finger double tap does nothing', strokes_after(function()
  tap({ fingers = 2 })
  pause(0.2)
  tap({ fingers = 2 })
end) == 0)
check('four-finger double tap does nothing', strokes_after(function()
  tap({ fingers = 4 })
  pause(0.2)
  tap({ fingers = 4 })
end) == 0)
check('a two-finger tap in between breaks the pair', strokes_after(function()
  tap()
  pause(0.1)
  tap({ fingers = 2 })
  pause(0.1)
  tap()
end) == 0)
check('triple tap fires once', strokes_after(function()
  for _ = 1, 3 do
    tap()
    pause(0.2)
  end
end) == 1)
check('quadruple tap fires twice', strokes_after(function()
  for _ = 1, 4 do
    tap()
    pause(0.2)
  end
end) == 2)
check('a cancelled contact does not count', strokes_after(function()
  tap()
  pause(0.2)
  tap({ cancel = true })
end) == 0)
check('a resting thumb is ignored', strokes_after(function()
  tap({ resting = true })
  pause(0.2)
  tap({ resting = true })
end) == 1)
check('a pressure event with no touches mid-tap does not end it', strokes_after(function()
  tap({ pressure = true })
  pause(0.2)
  tap({ pressure = true })
end) == 1)
check('touch bar touches are ignored', strokes_after(function()
  send(GESTURE, { { id = 'bar', phase = 'began', x = 0, y = 0, type = 'direct' } })
  tap()
  pause(0.2)
  tap()
end) == 1)

-- A recorded trackpad

load_config()
local start = state.now
for _, recorded in ipairs(dofile(tests .. '/fixtures/taps.lua')) do
  state.now = start + recorded.t
  send(recorded.ns, recorded.touches)
end
local combos = {}
for _, stroke in ipairs(state.strokes) do
  table.insert(combos, stroke.combo)
end
check(
  'recorded taps send cmd+w, then cmd+shift+t four times',
  table.concat(combos, ' ') == 'cmd+w cmd+shift+t cmd+shift+t cmd+shift+t cmd+shift+t'
)

io.stdout:write(failures == 0 and 'ALL PASS\n' or (failures .. ' FAILED\n'))
os.exit(failures == 0 and 0 or 1)
