--- @class utils.wheel-axis-lock
local M = {}

-- Sideways ticks in a row, with no vertical tick between, that make a swipe horizontal. Ticks fire
-- per cell and cells are far taller than wide, so any fewer would pan on diagonal vertical swipes
local ENGAGE_TICKS = 5
-- Gap between sideways ticks that ends a swipe: terminals report ticks, not gestures
local RELEASE_NS = 200e6

local last_sideways_tick = 0
local sideways_streak = 0
-- Set only by a tick that moved text: sideways ticks over text that fits must not block scrolling
local panning = false

--- @param now number
local function forget_ended_swipe(now)
  if now - last_sideways_tick >= RELEASE_NS then
    sideways_streak = 0
    panning = false
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
  local now = vim.uv.hrtime()
  forget_ended_swipe(now)
  last_sideways_tick = now
  sideways_streak = sideways_streak + 1
  if not panning and sideways_streak < ENGAGE_TICKS or not can_pan(left) then
    return false
  end

  panning = true
  return true
end

--- @return boolean
function M.left()
  return sideways(true)
end

--- @return boolean
function M.right()
  return sideways(false)
end

--- Whether a vertical tick should scroll: a pan drops lone ones as drift, and two in a row end it,
--- since a swipe that turns vertical keeps drifting sideways and so never reaches RELEASE_NS
--- @return boolean
function M.vertical()
  forget_ended_swipe(vim.uv.hrtime())
  local drift = panning and sideways_streak > 0
  sideways_streak = 0
  panning = drift
  return not drift
end

return M
