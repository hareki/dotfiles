-- features.git.git-conflict-nvim.utils: what the plugin's GitConflictDetected and
-- GitConflictResolved events set up and undo on a buffer, in the orders the plugin fires them, and
-- what the statusline reads from it

local t = require('tests.lib.helpers')
local git_conflict = require('features.git.git-conflict-nvim.utils')
local lazy = require('lazy')

-- Its config runs utils.setup(); the test cwd is no repository, so the plugin itself parses nothing
lazy.load({ plugins = { 'git-conflict.nvim' } })

-- The plugin's namespace, where a parsed conflict is one extmark over its region
local conflict_ns = vim.api.nvim_create_namespace('git-conflict')
local CONFLICT_WINHL =
  'DocumentHighlight:GitConflictDocumentHighlight,GitSignsCurrentLineBlame:GitConflictBlame'
local UNMERGED_ICON = Conf.icons.git.UNMERGED

-- The region the plugin would mark: lines 2 to 4
local LINES = { 'before', '<<<<<<< HEAD', 'ours', '>>>>>>> theirs', 'after' }

--- A file holding one conflict, current in the window, its region marked as the plugin marks it
--- @param name string
--- @return integer buf
local function conflicted_file(name)
  local buf = t.file(name, LINES)
  vim.api.nvim_buf_set_extmark(buf, conflict_ns, 1, 0, { end_row = 4, end_col = 0 })
  return buf
end

--- @param pattern 'GitConflictDetected' | 'GitConflictResolved'
--- @param buf integer
local function fire(pattern, buf)
  vim.api.nvim_exec_autocmds('User', { pattern = pattern, modeline = false, data = { buf = buf } })
end

--- @param buf integer
local function detected(buf)
  fire('GitConflictDetected', buf)
end

--- @param buf integer
local function resolved(buf)
  fire('GitConflictResolved', buf)
end

--- @param buf integer
--- @param lhs string
--- @return string? rhs nil when the buffer has no map on lhs
local function buf_rhs(buf, lhs)
  local map = t.keymap('n', lhs, buf)
  return map and map.rhs
end

--- @param buf integer
--- @return boolean
local function diagnostics_on(buf)
  return vim.diagnostic.is_enabled({ bufnr = buf })
end

--- Move the cursor of the current window the way a user does, firing CursorMoved
--- @param line integer
local function move_to(line)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.api.nvim_exec_autocmds('CursorMoved', { buf = vim.api.nvim_get_current_buf() })
end

--- Focus a new split on another buffer, closed with that buffer when the test ends
--- @return integer win
local function split_other()
  local buf = vim.api.nvim_create_buf(true, false)
  local win = vim.api.nvim_open_win(buf, false, { split = 'below' })
  vim.api.nvim_set_current_win(win)
  t.cleanup(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  return win
end

--- Wait for the statusline to show `text`, or to drop it
--- @param text string
--- @param shown boolean
--- @param msg string
local function await_statusline(text, shown, msg)
  t.wait_for(function()
    return (t.statusline():find(text, 1, true) ~= nil) == shown
  end, msg)
end

t.test('Detected maps the conflict keys and pauses diagnostics; Resolved undoes both', function()
  t.eq(package.loaded['colorizer'], nil, 'colorizer loaded before the test')
  local buf = conflicted_file('plain.txt')
  t.eq(git_conflict.is_conflicted(buf), false, 'conflicted before Detected')

  detected(buf)
  t.eq(git_conflict.is_conflicted(buf), true, 'conflicted after Detected')
  t.eq(buf_rhs(buf, '<leader>co'), '<Plug>(git-conflict-ours)', '<leader>co')
  t.eq(buf_rhs(buf, ']x'), '<Plug>(git-conflict-next-conflict)', ']x')
  t.eq(t.keymap('n', '<leader>ct', buf).desc, 'Git Conflict: Choose Theirs', 'a desc')
  t.eq(diagnostics_on(buf), false, 'diagnostics after Detected')

  resolved(buf)
  t.eq(git_conflict.is_conflicted(buf), false, 'conflicted after Resolved')
  t.eq(buf_rhs(buf, '<leader>co'), nil, '<leader>co after Resolved')
  t.eq(buf_rhs(buf, ']x'), nil, ']x after Resolved')
  t.eq(diagnostics_on(buf), true, 'diagnostics after Resolved')
  t.eq(package.loaded['colorizer'], nil, 'colorizer loaded by an unattached buffer')
end)

t.test('the conflict highlights follow the cursor in and out of the region', function()
  local buf = conflicted_file('cursor.txt')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(win, { 3, 0 })

  -- Detected sets them on the next tick: the plugin fires it from a decoration provider
  detected(buf)
  t.eq(vim.wo[win].winhighlight, '', 'set inside the event')
  t.wait_for(function()
    return vim.wo[win].winhighlight == CONFLICT_WINHL
  end, 'the highlights on the line inside the region')

  -- The region's extmark ends at column 0 of the line after it
  move_to(5)
  t.eq(vim.wo[win].winhighlight, '', 'on the line after the region')
  move_to(1)
  t.eq(vim.wo[win].winhighlight, '', 'on the line before the region')
  move_to(2)
  t.eq(vim.wo[win].winhighlight, CONFLICT_WINHL, 'on the first line of the region')

  -- A buffer swap in the window takes them off; coming back, nvim restores the cursor after
  -- BufEnter, and the CursorMoved it then fires puts them on
  local other = t.buffer()
  t.eq(vim.wo[win].winhighlight, '', 'with another buffer in the window')
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_exec_autocmds('CursorMoved', { buf = buf })
  t.eq(vim.wo[win].winhighlight, CONFLICT_WINHL, 'back on the conflicted buffer')
  vim.api.nvim_buf_delete(other, { force = true })

  -- Leaving the window takes them off too, and refocusing it puts them back
  local split = split_other()
  t.eq(vim.wo[win].winhighlight, '', 'with focus in another window')
  vim.api.nvim_set_current_win(win)
  t.eq(vim.wo[win].winhighlight, CONFLICT_WINHL, 'with focus back')

  -- Resolved clears every window showing the buffer
  vim.api.nvim_win_set_buf(split, buf)
  vim.api.nvim_set_current_win(split)
  move_to(3)
  t.eq(vim.wo[split].winhighlight, CONFLICT_WINHL, 'a second window showing it')
  resolved(buf)
  t.eq({ vim.wo[win].winhighlight, vim.wo[split].winhighlight }, { '', '' }, 'after Resolved')
end)

t.test("the conflict highlights keep the window's own redirects", function()
  local buf = conflicted_file('redirects.txt')
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].winhighlight = 'Normal:NormalFloat'
  t.cleanup(function()
    vim.wo[win].winhighlight = ''
  end)

  detected(buf)
  move_to(3)
  t.eq(vim.wo[win].winhighlight, 'Normal:NormalFloat,' .. CONFLICT_WINHL, 'after a redirect')

  vim.wo[win].winhighlight = vim.wo[win].winhighlight .. ',FloatBorder:Comment'
  move_to(1)
  t.eq(vim.wo[win].winhighlight, 'Normal:NormalFloat,FloatBorder:Comment', 'from between two')
  resolved(buf)
end)

t.test('a buffer Detected while another is current gets its highlights on entry', function()
  local buf = conflicted_file('background.txt')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(win, { 3, 0 })
  split_other()

  detected(buf)
  t.settle()
  t.eq(vim.wo[win].winhighlight, '', 'the window showing it, out of focus')

  vim.api.nvim_set_current_win(win)
  t.eq(vim.wo[win].winhighlight, CONFLICT_WINHL, 'after entering it')
  resolved(buf)
end)

t.test('Resolved deletes only the conflict maps, whatever state the buffer is in', function()
  local buf = conflicted_file('handover.txt')
  detected(buf)

  -- codediff's merge view claims a key on the buffer, and fires Resolved through the plugin
  vim.keymap.set('n', '<leader>co', '<Nop>', { buf = buf, desc = 'Merge View Key' })
  resolved(buf)
  local claimed = t.keymap('n', '<leader>co', buf)
  t.eq(claimed and claimed.desc, 'Merge View Key', "another plugin's map on a conflict key")
  t.eq(buf_rhs(buf, '<leader>ct'), nil, 'a conflict map left after Resolved')
  t.eq(git_conflict.is_conflicted(buf), false, 'conflicted after Resolved')
  t.eq(diagnostics_on(buf), true, 'diagnostics after Resolved')

  -- It hands Detected's map back once it lets go; the plugin's next parse fires Resolved again
  vim.keymap.set('n', '<leader>co', '<Plug>(git-conflict-ours)', { buf = buf })
  vim.diagnostic.enable(false, { bufnr = buf })
  resolved(buf)
  t.eq(buf_rhs(buf, '<leader>co'), nil, 'the handed-back map after a second Resolved')
  t.eq(diagnostics_on(buf), false, 'diagnostics paused by someone else, after a second Resolved')
  vim.diagnostic.enable(true, { bufnr = buf })
end)

t.test(
  ':bdelete between Detected and Resolved: diagnostics back on, a new Detected sets up',
  function()
    local buf = conflicted_file('deleted.txt')
    local path = vim.api.nvim_buf_get_name(buf)
    detected(buf)

    vim.cmd.bdelete(buf)
    t.eq(diagnostics_on(buf), true, 'diagnostics after :bdelete')
    t.eq(git_conflict.is_conflicted(buf), false, 'conflicted after :bdelete')

    vim.cmd.edit(vim.fn.fnameescape(path))
    t.eq(vim.api.nvim_get_current_buf(), buf, 'the same buffer, reloaded')
    detected(buf)
    t.eq(git_conflict.is_conflicted(buf), true, 'conflicted after the second Detected')
    t.eq(
      buf_rhs(buf, '<leader>co'),
      '<Plug>(git-conflict-ours)',
      'the maps after the second Detected'
    )
    t.eq(diagnostics_on(buf), false, 'diagnostics after the second Detected')
    resolved(buf)
  end
)

t.test('colorizer pauses in an attached buffer until Resolved, even when Detected twice', function()
  local buf = conflicted_file('colors.lua')
  local colorizer = require('colorizer')
  t.wait_for(function()
    return colorizer.is_buffer_attached(buf)
  end, 'colorizer to attach to the Lua buffer')

  detected(buf)
  t.eq(colorizer.is_buffer_attached(buf), false, 'attached after Detected')
  -- The plugin fires Detected on every parse
  detected(buf)
  t.eq(colorizer.is_buffer_attached(buf), false, 'attached after the second Detected')

  resolved(buf)
  t.eq(colorizer.is_buffer_attached(buf), true, 'attached after Resolved')
end)

t.test('with colorizer loaded, Resolved leaves a buffer it never served detached', function()
  t.ok(package.loaded['colorizer'], 'colorizer is not loaded')
  local colorizer = require('colorizer')
  local buf = conflicted_file('uncolored.txt')
  t.eq(colorizer.is_buffer_attached(buf), false, 'attached before Detected')

  detected(buf)
  resolved(buf)
  t.eq(colorizer.is_buffer_attached(buf), false, 'attached after Resolved')
end)

t.test('the statusline flags the current conflicted buffer, then counts it from another', function()
  local buf = conflicted_file('status.txt')
  await_statusline(UNMERGED_ICON, false, 'a statusline without the icon before Detected')

  detected(buf)
  await_statusline(UNMERGED_ICON, true, 'the icon for the current buffer')

  local other = t.file('status-other.txt', { 'clean' })
  await_statusline(UNMERGED_ICON .. ' 1', true, 'the count of other conflicted buffers')

  resolved(buf)
  await_statusline(UNMERGED_ICON, false, 'the icon to go after Resolved')
  vim.api.nvim_buf_delete(other, { force = true })
end)
