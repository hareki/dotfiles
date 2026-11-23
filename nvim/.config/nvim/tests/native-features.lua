-- The features built on Neovim alone (lazy.nvim `virtual` specs and after/ftplugin files): each
-- loads the way its spec says and brings its own options, keys and autocmds

local t = require('tests.lib.helpers')
local lazy_config = require('lazy.core.config')

--- @param name string A virtual spec's name
--- @return boolean
local function loaded(name)
  return t.ok(lazy_config.plugins[name], name .. ' is no plugin of this config')._.loaded ~= nil
end

--- @return integer[] wins The floats open now
local function floats()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative ~= ''
  end, vim.api.nvim_list_wins())
end

t.test('a virtual spec is installed from nowhere and adds nothing to the runtimepath', function()
  local virtual = vim.tbl_filter(function(plugin)
    return plugin.virtual == true
  end, vim.tbl_values(lazy_config.plugins))
  t.ok(#virtual > 0, 'no virtual spec found')

  for _, plugin in ipairs(virtual) do
    t.eq(plugin.url, nil, plugin.name .. ' has no url to clone')
    t.eq(
      vim.list_contains(vim.opt.runtimepath:get(), plugin.dir),
      false,
      plugin.name .. ' is off the runtimepath'
    )
  end
end)

t.test('hl-at-cursor stays unloaded until its key, which opens the popup', function()
  t.eq(loaded('hl-at-cursor'), false, 'nothing has asked for it yet')
  t.file('hl-at-cursor.lua', { 'local answer = 42' })
  local before = #floats()
  t.cleanup(function()
    for _, win in ipairs(floats()) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end)

  vim.api.nvim_feedkeys(vim.keycode('<leader>?h'), 'mx', false)

  t.eq(loaded('hl-at-cursor'), true, 'the key loads it')
  t.eq(vim.fn.exists(':HlAtCursor'), 2, 'its command is the real one')
  t.wait_for(function()
    return #floats() > before
  end, 'the popup to open')
end)

t.test('the wheel axis lock maps the wheel keys on VeryLazy, passing a vertical tick', function()
  t.eq(loaded('wheel-axis-lock'), true, 'VeryLazy loads it')
  t.eq(vim.o.mousescroll, 'ver:3,hor:2', 'its init sets the scroll speed')

  for _, mode in ipairs({ 'n', 'x', 's', 'i', 't' }) do
    t.ok(t.keymap(mode, '<ScrollWheelLeft>'), 'no sideways map in mode ' .. mode)
  end
  t.eq(t.map_callback('n', '<ScrollWheelUp>')(), '<ScrollWheelUp>', 'a vertical tick scrolls')
end)

-- Where the fake clock of the last wheel test stopped, so the next one starts past any swipe
local wheel_clock = 0

--- Drive the wheel lock over `win` until the test ends: the mouse rests on it, and the clock moves
--- only when told, starting a second past any swipe an earlier test left
--- @param win integer
--- @return fun(key: string, ms?: integer): string tick The key a tick `ms` after the last one maps to
local function wheel_over(win)
  wheel_clock = math.max(wheel_clock, vim.uv.hrtime()) + 1e9
  t.set(vim.uv, 'hrtime', function()
    return wheel_clock
  end)
  t.set(vim.fn, 'getmousepos', function()
    return { winid = win }
  end)

  return function(key, ms)
    wheel_clock = wheel_clock + (ms or 10) * 1e6
    return t.map_callback('n', key)()
  end
end

--- A window of long lines that pan, current in a tab of its own
--- @return integer win
local function wide_window()
  t.tab()
  t.buffer(nil, { string.rep('wide ', 40), string.rep('line ', 40) })
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].wrap = false
  return win
end

--- @param tick fun(key: string, ms?: integer): string
--- @param key string
--- @param count integer
--- @return string[] keys What each of `count` ticks of `key` maps to
local function ticks(tick, key, count)
  local keys = {}
  for i = 1, count do
    keys[i] = tick(key)
  end
  return keys
end

local IGNORE = '<Ignore>'
local RIGHT = '<ScrollWheelRight>'
local LEFT = '<ScrollWheelLeft>'
local UP = '<ScrollWheelUp>'
local DOWN = '<ScrollWheelDown>'

t.test('the wheel axis lock pans from the fifth sideways tick until a 200 ms gap', function()
  local tick = wheel_over(wide_window())

  t.eq(ticks(tick, RIGHT, 6), { IGNORE, IGNORE, IGNORE, IGNORE, RIGHT, RIGHT }, 'the swipe')
  t.eq(tick(RIGHT, 150), RIGHT, 'a tick 150 ms on, still in the swipe')
  t.eq(tick(RIGHT, 300), IGNORE, 'a tick 300 ms on, a new swipe')

  ticks(tick, RIGHT, 5)
  t.eq(tick(UP, 300), UP, 'a vertical tick 300 ms after a pan')
end)

t.test('the wheel axis lock pans left only from a scrolled window', function()
  local win = wide_window()
  local tick = wheel_over(win)

  t.eq(ticks(tick, LEFT, 6), { IGNORE, IGNORE, IGNORE, IGNORE, IGNORE, IGNORE }, 'at column 0')
  vim.fn.winrestview({ leftcol = 20 })
  t.eq(tick(LEFT), LEFT, 'scrolled right, in the same swipe')
  vim.fn.winrestview({ leftcol = 0 })
  t.eq(tick(LEFT), IGNORE, 'back at column 0')
end)

t.test('the wheel axis lock drops a lone vertical tick in a pan; two in a row end it', function()
  local tick = wheel_over(wide_window())
  ticks(tick, RIGHT, 5)

  t.eq(tick(UP), IGNORE, 'a lone vertical tick in the pan')
  t.eq(tick(RIGHT), RIGHT, 'the pan goes on')
  t.eq({ tick(DOWN), tick(DOWN) }, { IGNORE, DOWN }, 'two vertical ticks in a row')
  t.eq(tick(RIGHT), IGNORE, 'a sideways tick after them, which starts a new swipe')
end)

t.test('the wheel axis lock drops sideways drift in a vertical swipe', function()
  local tick = wheel_over(wide_window())

  for round = 1, 3 do
    t.eq(tick(DOWN), DOWN, 'a vertical tick, round ' .. round)
    t.eq(ticks(tick, RIGHT, 4), { IGNORE, IGNORE, IGNORE, IGNORE }, 'the drift, round ' .. round)
  end
end)

t.test('the wheel axis lock never pans text that fits, nor blocks scrolling there', function()
  t.tab()
  t.buffer(nil, { 'short' })
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].wrap = false
  local tick = wheel_over(win)

  t.eq(ticks(tick, RIGHT, 6), { IGNORE, IGNORE, IGNORE, IGNORE, IGNORE, IGNORE }, 'the swipe')
  t.eq(tick(UP), UP, 'a vertical tick after it')

  vim.wo[win].wrap = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep('wide ', 40) })
  t.eq(ticks(tick, RIGHT, 6)[6], IGNORE, 'a wrapping window, whose lines overflow')
end)

t.test('diagnostics take their display from the feature and their jump popup from eagle', function()
  local config = t.ok(vim.diagnostic.config(), 'no diagnostic config')
  t.eq(config.severity_sort, true, 'the display config applied')
  t.eq(type(config.jump.on_jump), 'function', "eagle's on_jump survived it")
  t.eq(t.ok(t.keymap('n', ']e'), ']e is unmapped').desc, 'Next Error')
end)

t.test('a markdown buffer wraps its lines and jumps sections in Visual mode', function()
  t.file('plain.txt', { 'text' })
  t.eq(vim.wo.wrap, false, 'other buffers keep nowrap')

  local buf = t.file('note.md', { '# One', 'text', '## Two' })
  t.eq(vim.wo.wrap, true, 'markdown wraps')
  t.eq(t.ok(t.keymap('x', ']]', buf), 'no visual ]]').desc, 'Jump to Next Section')
  t.eq(t.ok(t.keymap('x', '[[', buf), 'no visual [[').desc, 'Jump to Previous Section')
end)

t.test('the cursor line number takes the color of the mode', function()
  vim.api.nvim_exec_autocmds('ModeChanged', { modeline = false })
  t.eq(vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).link, UI.mode.group())
  t.ok(vim.api.nvim_get_hl(0, { name = UI.mode.group() }).fg, 'the mode group has no color')
end)

t.test('a Ghostty config comments its lines with #', function()
  t.buffer('ghostty')
  t.eq(vim.bo.commentstring, '# %s')
end)

t.test('a man page stays out of the buffer list', function()
  vim.cmd('Man printf')
  local buf = vim.api.nvim_get_current_buf()
  t.cleanup(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  t.eq(vim.bo[buf].filetype, 'man', 'the page opened')
  t.eq(vim.bo[buf].buflisted, false)
end)
