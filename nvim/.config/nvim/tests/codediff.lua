-- features.git.codediff-nvim.utils, through the real :CodeDiff: closing a codediff tab shows the
-- file and scroll last selected in it (restore_focus), and exit closes every such tab (close_tabs)

local t = require('tests.lib.helpers')

local CWD = assert(vim.uv.cwd())
local CLOSE_TABS_GROUP = 'features.git.codediff-nvim.close-tabs-on-exit'

--- @param cmd string[]
local function run(cmd)
  local result = vim.system(cmd, { cwd = CWD, text = true }):wait()
  assert(result.code == 0, table.concat(cmd, ' ') .. ': ' .. result.stderr)
end

--- @param name string
--- @return string
local function path_of(name)
  return vim.fs.joinpath(CWD, name)
end

-- A repository whose two files have changes, one far enough down to scroll to
local ONE = {}
for i = 1, 80 do
  ONE[i] = 'line ' .. i
end
vim.fn.writefile(ONE, path_of('one.txt'))
vim.fn.writefile({ 'two' }, path_of('two.txt'))
run({ 'git', 'init', '-q' })
run({ 'git', 'add', '.' })
run({ 'git', '-c', 'user.name=test', '-c', 'user.email=test@test', 'commit', '-q', '-m', 'init' })
ONE[60] = 'changed'
vim.fn.writefile(ONE, path_of('one.txt'))
vim.fn.writefile({ 'two changed' }, path_of('two.txt'))

--- @return integer[]
local function codediff_tabs()
  local codediff_utils = require('features.git.codediff-nvim.utils')
  return vim.tbl_filter(codediff_utils.is_codediff_tab, vim.api.nvim_list_tabpages())
end

--- The window of the file `name`, once the modified pane of the current codediff tab shows it
--- @param name string
--- @return integer win
local function await_modified_pane(name)
  local lifecycle = require('codediff.ui.lifecycle')
  local win
  t.wait_for(function()
    _, win = lifecycle.get_windows(vim.api.nvim_get_current_tabpage())
    return win ~= nil
      and vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path_of(name)
  end, 'the modified pane to show ' .. name)
  return win
end

--- Press <leader>g for a codediff tab of the repository's changes, which selects the first file;
--- its tabs and the repository's buffers go when the test ends
--- @return integer win The modified pane
local function open_codediff()
  t.cleanup(function()
    for _, tab in ipairs(codediff_tabs()) do
      vim.api.nvim_set_current_tabpage(tab)
      vim.cmd.tabclose()
    end
    t.settle()
    for _, name in ipairs({ 'one.txt', 'two.txt' }) do
      local buf = vim.fn.bufnr(path_of(name))
      if buf ~= -1 then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end)

  local before = #vim.api.nvim_list_tabpages()
  t.press('<leader>g')
  t.wait_for(function()
    return #vim.api.nvim_list_tabpages() > before
  end, 'the codediff tab')
  return await_modified_pane('one.txt')
end

--- Scroll the modified pane down to `line`, the cursor on it
--- @param win integer
--- @param line integer
--- @return integer topline
local function scroll_to(win, line)
  vim.api.nvim_win_set_cursor(win, { line, 0 })
  return vim.api.nvim_win_call(win, function()
    vim.cmd('normal! zt')
    return vim.fn.line('w0')
  end)
end

--- @return string name The current buffer's file, relative to the repository
--- @return integer line
--- @return integer topline
local function where()
  local name = vim.fs.relpath(CWD, vim.api.nvim_buf_get_name(0)) or ''
  return name, vim.api.nvim_win_get_cursor(0)[1], vim.fn.line('w0')
end

t.test(
  'closing the tab shows its file in the first tab, scrolled as the modified pane was',
  function()
    local first = vim.api.nvim_get_current_tabpage()
    local topline = scroll_to(open_codediff(), 60)
    t.ok(topline > 1, 'the pane did not scroll')

    vim.cmd.tabclose()
    t.eq(vim.api.nvim_get_current_tabpage(), first, 'the tab after closing')
    t.wait_for(function()
      return (where()) == 'one.txt'
    end, 'the first tab to show the file')
    t.eq({ where() }, { 'one.txt', 60, topline }, 'the file, line and top line')
  end
)

t.test('closing the tab shows the file selected last in its explorer', function()
  open_codediff()
  local lifecycle = require('codediff.ui.lifecycle')
  local explorer = t.ok(
    vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(win)
      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'codediff-explorer'
    end),
    'no explorer window'
  )
  local explorer_buf = vim.api.nvim_win_get_buf(explorer)
  local one_line = t.ok(
    vim.iter(ipairs(vim.api.nvim_buf_get_lines(explorer_buf, 0, -1, false))):find(function(_, line)
      return line:find('one.txt', 1, true) ~= nil
    end),
    'no one.txt in the explorer'
  )

  -- auto_open_on_cursor: moving onto a file selects it
  vim.api.nvim_set_current_win(explorer)
  vim.api.nvim_win_set_cursor(explorer, { one_line, 0 })
  t.map_callback('n', 'j', explorer_buf)()
  await_modified_pane('two.txt')
  t.ok(lifecycle.get_session(vim.api.nvim_get_current_tabpage()), 'the session')

  vim.cmd.tabclose()
  t.wait_for(function()
    return (where()) == 'two.txt'
  end, 'the first tab to show the selected file')
end)

t.test('a selected file gone from disk by the close opens nothing', function()
  local before = vim.api.nvim_get_current_buf()
  open_codediff()
  vim.fn.rename(path_of('one.txt'), path_of('one.txt.moved'))
  t.cleanup(function()
    vim.fn.rename(path_of('one.txt.moved'), path_of('one.txt'))
  end)

  vim.cmd.tabclose()
  t.settle()
  t.eq(vim.api.nvim_get_current_buf(), before, 'the buffer of the first tab')
end)

t.test('the exit path closes the codediff tabs, leaving the others as they were', function()
  local first = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()
  open_codediff()

  vim.api.nvim_exec_autocmds('VimLeavePre', { group = CLOSE_TABS_GROUP, modeline = false })
  t.eq(codediff_tabs(), {}, 'the codediff tabs')
  t.eq(vim.api.nvim_list_tabpages(), { first }, 'the tabs')
  t.settle()
  t.eq(vim.api.nvim_get_current_buf(), buf, 'the buffer of the first tab')
end)

t.test('the exit path swaps a last codediff tab for its file, scrolled, at once', function()
  local win = open_codediff()
  -- The boot's own tab goes, so this test comes last
  local codediff_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd.tabonly()
  t.eq(vim.api.nvim_list_tabpages(), { codediff_tab }, 'the tabs before the exit path')
  local topline = scroll_to(win, 60)

  vim.api.nvim_exec_autocmds('VimLeavePre', { group = CLOSE_TABS_GROUP, modeline = false })

  -- Synchronous: the session save runs right after this autocmd
  t.eq(codediff_tabs(), {}, 'the codediff tabs')
  t.eq(#vim.api.nvim_list_tabpages(), 1, 'the tabs')
  t.eq({ where() }, { 'one.txt', 60, topline }, 'the file, line and top line')
  t.settle()
  local windows = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ''
  end, vim.api.nvim_tabpage_list_wins(0))
  t.eq(#windows, 1, 'the windows, once CodeDiffClose has run')
end)
