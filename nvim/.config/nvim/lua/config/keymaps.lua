local map = vim.keymap.set

--- @module 'utils.wheel-axis-lock'
local wheel_axis_lock = Defer.on_exported_call('utils.wheel-axis-lock')

local function scroll_center(motion)
  local keys = vim.keycode(motion)
  return function()
    -- 'x' executes synchronously so the cursor position is updated before we
    -- decide whether centering is safe; mode (incl. visual) is preserved.
    vim.api.nvim_feedkeys(keys, 'nx', false)

    local win_height = vim.api.nvim_win_get_height(0)
    local last_line = vim.fn.line('$')
    local cursor_line = vim.fn.line('.')

    if last_line - cursor_line >= math.floor(win_height / 2) then
      vim.cmd.normal({ 'zz', bang = true })
    end
  end
end

-- Drop a tick with <Ignore>: an empty expr result leaves it in vim.on_key's `typed`, glued to the
-- next key, which then fails the exact matches in Snacks' picker list and multicursor
local function map_wheel(key, desc, passes)
  map({ 'n', 'x', 's', 'i', 't' }, key, function()
    return passes() and key or '<Ignore>'
  end, { expr = true, desc = desc })
end

-- Jumplist keys as no-ops in non-file buffers, decided per keypress: <C-i> is <Tab>, so a
-- buffer-local <Nop> set on BufEnter would also shadow a UI buffer's own <Tab> map
local function jumplist(key)
  return function()
    return vim.bo.buftype == '' and key or ''
  end
end

map('n', 'Q', '<cmd>q<cr>', { desc = 'Close Window' })

-- Fall back to native <CR> in nomodifiable buffers (help, man, checkhealth, ...), where
-- feeding `a` would raise E21, and in the command-line window, where it runs the command
map('n', '<CR>', function()
  if vim.bo.modifiable and vim.fn.win_gettype() ~= 'command' then
    return 'a<CR><Esc>'
  end
  return '<CR>'
end, { expr = true, desc = 'Insert Newline After Cursor' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave Terminal Mode' })

map('n', '<Esc>', function()
  UI.color.nohlsearch()
  vim.snippet.stop()

  -- noice lazy-loads nvim-notify, and nothing can be on screen before it does
  local notify = package.loaded['notify']
  if notify then
    -- `{ pending = true, silent = true }` would also drop queued notifications waiting for room
    notify.dismiss()
  end
end, { desc = 'Clear Highlight and Notifications' })

-- Sent for Cmd+Shift+W by the ghostty config; inspect with :echo keytrans(getcharstr())
map({ 'i', 'x', 'n', 's' }, '<C-S-End>', function()
  Snacks.bufdelete.other()
  Notifier.info('Closed Other Buffers')
end, { desc = 'Close Other Buffers' })

-- In a Snacks terminal the first `qa` only closes it; elsewhere a second one would repeat the
-- 'confirm' prompt after a Cancel
map({ 'n', 'x' }, '<leader>qa', function()
  return vim.b.snacks_terminal and '<cmd>qa<cr><cmd>qa<cr>' or '<cmd>qa<cr>'
end, { expr = true, desc = 'Quit All' })

map({ 'n', 'x' }, '<PageUp>', scroll_center('<C-u>'), { desc = 'Scroll Up and Center' })
map({ 'n', 'x' }, '<PageDown>', scroll_center('<C-d>'), { desc = 'Scroll Down and Center' })

-- Lock each trackpad swipe to one axis, as browsers do: terminals report every bit of drift
map_wheel('<ScrollWheelUp>', 'Scroll Up', wheel_axis_lock.vertical)
map_wheel('<ScrollWheelDown>', 'Scroll Down', wheel_axis_lock.vertical)
map_wheel('<ScrollWheelLeft>', 'Scroll Left', wheel_axis_lock.left)
map_wheel('<ScrollWheelRight>', 'Scroll Right', wheel_axis_lock.right)

map('v', '<leader>t', "ygvgc']p", {
  remap = true,
  desc = 'Yank, Comment, Move Below, and Paste',
})

map('n', '<leader>?h', '<cmd>HlAtCursor<cr>', {
  desc = 'Highlight Groups at Cursor',
})

-- Keep the selection after indenting
map('v', '<', '<gv', { desc = 'Indent Left' })
map('v', '>', '>gv', { desc = 'Indent Right' })

-- Better up/down: display lines unless a count above 1 is given (the typed count applies to
-- the returned keys). They run unmapped, since 'j'/'k' might be remapped for other purposes
map({ 'n', 'x' }, '<Down>', function()
  return vim.v.count1 == 1 and 'gj' or 'j'
end, { expr = true, desc = 'Down', silent = true })

map({ 'n', 'x' }, '<Up>', function()
  return vim.v.count1 == 1 and 'gk' or 'k'
end, { expr = true, desc = 'Up', silent = true })

map('n', 'yow', '<cmd>setlocal wrap!<cr>', { desc = 'Toggle Line Wrap' })

map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Plugin Manager' })
map('n', '<leader>-', '<cmd>split<cr>', { desc = 'Split Window Below' })
map('n', '<leader>\\', '<cmd>vsplit<cr>', { desc = 'Split Window Right' })

-- Jumplist
map('n', '<C-o>', jumplist('<C-o>'), { expr = true, desc = 'Jumplist Back' })
map('n', '<C-i>', jumplist('<C-i>'), { expr = true, desc = 'Jumplist Forward' })

-- Buffer (Neovim's own ]b/[b/]B/[B take counts; config/builtin-keymaps.lua titles them)
map(
  { 'i', 'x', 'n', 's' },
  '<A-r>',
  '<cmd>edit!<cr>',
  { desc = 'Reload Current Buffer', silent = true }
)

map({ 'i', 'x', 'n', 's' }, '<A-w>', function()
  Snacks.bufdelete()
end, { desc = 'Close Buffer' })
