--- @class features.navigation.wheel-axis-lock.utils
local M = {}

-- Sideways ticks in a row, with no vertical tick between, that make a swipe horizontal. Ticks fire
-- per cell and cells are far taller than wide, so any fewer would pan on diagonal vertical swipes
local ENGAGE_TICKS = 5
-- Gap between sideways ticks that ends a swipe: terminals report ticks, not gestures
local RELEASE_NS = 200e6

--- @class features.navigation.wheel-axis-lock.utils.State
--- @field last_sideways_tick number hrtime() of the last sideways tick
--- @field sideways_streak integer Sideways ticks since the last vertical one or the swipe's start
--- @field panning boolean Whether the swipe moves text sideways

--- @type features.navigation.wheel-axis-lock.utils.State
local state = {
  last_sideways_tick = 0,
  sideways_streak = 0,
  -- Set only by a tick that moved text: sideways ticks over text that fits must not block scrolling
  panning = false,
}

local function forget_ended_swipe()
  if vim.uv.hrtime() - state.last_sideways_tick >= RELEASE_NS then
    state.sideways_streak = 0
    state.panning = false
  end
end

--- Whether any line on screen runs past the right edge of a window
--- @param info vim.fn.getwininfo.ret.item
--- @return boolean
local function overflows_right(info)
  local right_edge = info.leftcol + info.width - info.textoff
  return vim.api.nvim_win_call(info.winid, function()
    local lnum = info.topline
    while lnum <= info.botline do
      -- virtcol() puts `$` one column past the last character
      if vim.fn.virtcol({ lnum, '$' }) - 1 > right_edge then
        return true
      end
      -- A closed fold shows a single line, whatever the lines inside it hold
      lnum = math.max(lnum, vim.fn.foldclosedend(lnum)) + 1
    end
    return false
  end)
end

--- Whether a sideways tick would move text in the window under the mouse
--- @param left boolean
--- @return boolean
local function can_pan(left)
  local win = vim.fn.getmousepos().winid
  -- Terminal mode forwards a tick to a job that reads the mouse, which no API reveals, and a nested
  -- editor has its own text to pan
  if vim.fn.mode() == 't' and win == vim.api.nvim_get_current_win() then
    return true
  end

  if win == 0 or vim.wo[win].wrap then
    return false
  end

  local info = vim.fn.getwininfo(win)[1]
  if left then
    return info.leftcol > 0
  end
  return overflows_right(info)
end

--- Whether a sideways tick should pan: only in a horizontal swipe over text that overflows
--- @param left boolean
--- @return boolean
local function sideways(left)
  forget_ended_swipe()
  state.last_sideways_tick = vim.uv.hrtime()
  state.sideways_streak = state.sideways_streak + 1
  if not state.panning and state.sideways_streak < ENGAGE_TICKS or not can_pan(left) then
    return false
  end

  state.panning = true
  return true
end

--- @return boolean
local function left()
  return sideways(true)
end

--- @return boolean
local function right()
  return sideways(false)
end

--- Whether a vertical tick should scroll: a pan drops lone ones as drift, and two in a row end it,
--- since a swipe that turns vertical keeps drifting sideways and so never reaches RELEASE_NS
--- @return boolean
local function vertical()
  forget_ended_swipe()
  local drift = state.panning and state.sideways_streak > 0
  state.sideways_streak = 0
  state.panning = drift
  return not drift
end

--- Map a wheel key to itself while `passes`, else to <Ignore>: an empty expr result stays in
--- vim.on_key's `typed`, glued to the next key, so Snacks' list and multicursor miss exact matches
--- @param key string
--- @param desc string
--- @param passes fun(): boolean
local function map_wheel(key, desc, passes)
  vim.keymap.set({ 'n', 'x', 's', 'i', 't' }, key, function()
    return passes() and key or '<Ignore>'
  end, { expr = true, desc = desc })
end

--- @return nil
function M.map_wheel_keys()
  map_wheel('<ScrollWheelUp>', 'Scroll Up', vertical)
  map_wheel('<ScrollWheelDown>', 'Scroll Down', vertical)
  map_wheel('<ScrollWheelLeft>', 'Scroll Left', left)
  map_wheel('<ScrollWheelRight>', 'Scroll Right', right)
end

return M
