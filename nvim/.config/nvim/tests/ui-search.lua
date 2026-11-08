-- UI.search: search matches showing hide Snacks word references, and clearing the search brings
-- them back, from <Esc>, from entering Insert mode or by a direct call

local t = require('tests.lib.helpers')

--- Leave `pattern` highlighted, the way a `/` search does
--- @param pattern string
local function search(pattern)
  vim.fn.setreg('/', pattern)
  vim.v.hlsearch = 1
end

t.test('a search shows only with a pattern, not on v:hlsearch alone', function()
  vim.fn.setreg('/', '')
  vim.v.hlsearch = 1
  t.eq(UI.search.is_active(), false, 'no pattern, no search')

  search('needle')
  t.eq(UI.search.is_active(), true, 'a highlighted pattern shows')

  vim.v.hlsearch = 0
  t.eq(UI.search.is_active(), false, 'nothing shows after :nohlsearch')
end)

t.test('the Snacks.words filter hides references while a search shows', function()
  local filter = Snacks.config.words.filter
  local buf = vim.api.nvim_get_current_buf()

  search('needle')
  t.eq(filter(buf), false, 'references hide over a search')
  vim.v.hlsearch = 0
  t.eq(filter(buf), true, 'references show with no search')
end)

t.test('clear() turns the highlight off and refills references only after a search', function()
  local snacks_words = require('snacks.words')
  local updates, restore = t.spy(snacks_words, 'update', function() end)

  search('needle')
  UI.search.clear()
  t.eq(vim.v.hlsearch, 0, 'the highlight goes')
  t.eq(#updates, 1, 'references refill after a search')

  UI.search.clear()
  t.eq(#updates, 1, 'no refill with nothing highlighted')

  vim.fn.setreg('/', '')
  vim.v.hlsearch = 1
  UI.search.clear()
  t.eq(vim.v.hlsearch, 0, 'v:hlsearch goes without a pattern too')
  t.eq(#updates, 1, 'no refill when nothing was hidden')

  restore()
end)

t.test('<Esc> in Normal mode and entering Insert mode clear the search', function()
  t.buffer(nil, { 'needle in a haystack' })

  search('needle')
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'x', false)
  t.eq(vim.v.hlsearch, 0, '<Esc> clears the search')

  search('needle')
  -- Cleared from a scheduled callback, since autocmds restore the highlight state on return
  vim.api.nvim_feedkeys('i', 'x', false)
  t.wait_for(function()
    return vim.v.hlsearch == 0
  end, 'InsertEnter to clear the search')
end)
