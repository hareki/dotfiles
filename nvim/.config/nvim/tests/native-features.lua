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
