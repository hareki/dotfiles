-- tests.lib.helpers: what a test acquires through the helpers is undone when it ends, so the second
-- test here finds none of what the first one leaves open

local t = require('tests.lib.helpers')

local subject = {
  value = 'original',
  call = function()
    return 'original'
  end,
}

--- What the first test leaves for the second to look for
--- @type { tab?: integer, buf?: integer, file?: integer, float?: integer, picker?: snacks.Picker, cleaned: string[] }
local left = { cleaned = {} }

t.test('a test leaves open what it acquired', function()
  t.cleanup(function()
    left.cleaned[#left.cleaned + 1] = 'first'
  end)
  t.cleanup(function()
    left.cleaned[#left.cleaned + 1] = 'second'
  end)
  t.set(subject, 'value', 'set')
  t.set(vim.env, 'NVIM_TEST_LEFT', '1')
  local calls = t.spy(subject, 'call', function()
    return 'fake'
  end)
  left.tab = t.tab()
  left.buf = t.buffer('lua', { 'return {}' })
  left.file = t.file('left.txt', { 'left' })
  left.float = t.float()
  left.picker = t.open_picker(function()
    Snacks.picker.keymaps()
  end, 'keymaps')

  t.eq(subject.call(), 'fake', 'the fake answers')
  t.eq(#calls, 1, 'the call is recorded')
  t.eq(#vim.api.nvim_list_tabpages(), 2, 'the tab is open')
end)

t.test('the next test finds none of it', function()
  t.eq(subject.value, 'original', 'the set field')
  t.eq(vim.env.NVIM_TEST_LEFT, nil, 'the environment variable')
  t.eq(subject.call(), 'original', 'the spied function')
  t.eq(vim.api.nvim_tabpage_is_valid(left.tab), false, 'the tab')
  t.eq(vim.api.nvim_buf_is_valid(left.buf), false, 'the scratch buffer')
  t.eq(vim.api.nvim_buf_is_valid(left.file), false, 'the file buffer')
  t.eq(vim.api.nvim_win_is_valid(left.float), false, 'the float')
  t.eq(left.picker.closed, true, 'the picker')
  t.eq(left.cleaned, { 'second', 'first' }, 'its own cleanups, the newest first')
end)
