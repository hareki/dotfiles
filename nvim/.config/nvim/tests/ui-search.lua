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
  local updates = t.spy(snacks_words, 'update', function() end)

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
end)

t.test('<Esc> in Normal mode and entering Insert mode clear the search', function()
  t.buffer(nil, { 'needle in a haystack' })

  search('needle')
  t.press('<Esc>')
  t.eq(vim.v.hlsearch, 0, '<Esc> clears the search')

  search('needle')
  -- Cleared from a scheduled callback, since autocmds restore the highlight state on return
  t.press('i')
  t.wait_for(function()
    return vim.v.hlsearch == 0
  end, 'InsertEnter to clear the search')
end)

t.test('terminal windows hide search matches, every other window keeps them', function()
  t.tab()
  t.buffer(nil, { 'needle in a haystack' })
  local file_win = vim.api.nvim_get_current_win()

  vim.cmd('botright new')
  local term_win = vim.api.nvim_get_current_win()
  local term_buf = vim.api.nvim_get_current_buf()
  t.cleanup(function()
    pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
  end)
  vim.fn.jobstart({ 'printf', 'needle in a haystack' }, { term = true })
  t.wait_for(function()
    return vim.api.nvim_buf_get_lines(term_buf, 0, 1, false)[1] == 'needle in a haystack'
  end, 'the terminal to print')

  --- @param win integer
  --- @return boolean
  local function match_shown(win)
    vim.cmd.redraw({ bang = true })
    local match, plain = vim.fn.screenpos(win, 1, 1), vim.fn.screenpos(win, 1, 8)
    return vim.fn.screenattr(match.row, match.col) ~= vim.fn.screenattr(plain.row, plain.col)
  end

  search('needle')
  t.eq(match_shown(file_win), true, 'the file window shows the match')
  t.eq(match_shown(term_win), false, 'the terminal window hides it')

  -- Snacks and other plugins replace the whole option, as a re-shown terminal does
  vim.wo[term_win].winhighlight = 'Normal:NormalFloat'
  t.eq(match_shown(term_win), false, 'a replaced winhighlight still hides it')

  vim.api.nvim_win_set_buf(term_win, vim.api.nvim_win_get_buf(file_win))
  t.eq(match_shown(term_win), true, 'a file buffer swapped into the window shows it again')
  t.eq(vim.wo[term_win].winhighlight:find('Search:', 1, true), nil, 'the redirect comes off')
end)
