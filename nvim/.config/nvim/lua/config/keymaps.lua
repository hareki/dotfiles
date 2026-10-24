local del = vim.keymap.del
local map = vim.keymap.set

--- @module 'utils.style-enforcers'
local style_enforcers = Defer.on_exported_call('utils.style-enforcers')

local function open_line_diagnostics()
  vim.cmd.EagleWinLineDiagnostic()
end

local function diagnostic_goto(next, severity)
  local count = next and 1 or -1
  severity = severity and vim.diagnostic.severity[severity]

  return function()
    -- on_jump runs scheduled, and only once the jump succeeded
    vim.diagnostic.jump({ severity = severity, count = count, on_jump = open_line_diagnostics })
  end
end

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
      vim.cmd.normal({ args = { 'zz' }, bang = true })
    end
  end
end

-- Jumplist keys as no-ops in non-file buffers, decided per keypress: <C-i> is <Tab>, so a
-- buffer-local <Nop> set on BufEnter would also shadow a UI buffer's own <Tab> map
local function jumplist(key)
  return function()
    return vim.bo.buftype == '' and key or ''
  end
end

-- Clean up unused keymaps
for _, key in ipairs({
  ']a',
  '[a',
  '[A',
  ']A',
  ']l',
  '[l',
  ']L',
  '[L',
  ']Q',
  '[Q',
  ']<C-L>',
  '[<C-L>',
  ']<C-Q>',
  '[<C-Q>',
  ']<C-T>',
  '[<C-T>',
}) do
  pcall(del, 'n', key)
end

map('n', 'Q', '<cmd>q<cr>', { desc = 'Close Window' })

-- Fall back to native <CR> in nomodifiable buffers (help, man, checkhealth, ...),
-- where feeding `a` would raise E21
map('n', '<CR>', function()
  return vim.bo.modifiable and 'a<CR><Esc>' or '<CR>'
end, { expr = true, desc = 'Insert Newline After Cursor' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave Terminal Mode' })

map('n', '<Esc>', function()
  UI.color.nohlsearch()
  vim.snippet.stop()

  -- noice lazy-loads nvim-notify, and nothing can be on screen before it does
  local notify = package.loaded['notify']
  if notify then
    -- `{ pending = true, silent = true }` also drops queued notifications waiting for room
    notify.dismiss()
  end
end, { desc = 'Clear Highlight and Notifications' })

map({ 'n', 'i' }, '<A-s>', style_enforcers.run, { desc = 'Format and Save' })

map('n', '<leader>F', function()
  -- Still partially save the file when linter is oxlint, see `lua/utils/style-enforcers/oxlint.lua`
  style_enforcers.run({
    save = false,
  })
end, { desc = 'Format' })

-- Sent for Cmd+Shift+S by the ghostty config; inspect with :echo keytrans(getcharstr())
map({ 'n', 'i' }, '<F40>', style_enforcers.run_all, { desc = 'Format and Save All' })

-- Sent for Cmd+Shift+W by the ghostty config; inspect with :echo keytrans(getcharstr())
map({ 'i', 'x', 'n', 's' }, '<C-S-End>', function()
  Snacks.bufdelete.other()
  Notifier.info('Closed Other Buffers')
end, { desc = 'Close Other Buffers' })

map({ 'n', 'x' }, '<leader>qa', '<cmd>qa<cr>', { desc = 'Quit All' })
map({ 'n', 'x' }, '<PageUp>', scroll_center('<C-u>'), { desc = 'Scroll Up and Center' })
map({ 'n', 'x' }, '<PageDown>', scroll_center('<C-d>'), { desc = 'Scroll Down and Center' })

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

-- Diagnostics
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
map('n', '[d', diagnostic_goto(false), { desc = 'Previous Diagnostic' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Previous Error' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Previous Warning' })
map('n', ']i', diagnostic_goto(true, 'INFO'), { desc = 'Next Info' })
map('n', '[i', diagnostic_goto(false, 'INFO'), { desc = 'Previous Info' })

-- Buffer
map('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
map('n', ']B', '<cmd>blast<cr>', { desc = 'Last Buffer' })
map('n', '[b', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
map('n', '[B', '<cmd>brewind<cr>', { desc = 'First Buffer' })

map(
  { 'i', 'x', 'n', 's' },
  '<A-r>',
  '<cmd>edit!<cr>',
  { desc = 'Reload Current Buffer', silent = true }
)

map({ 'i', 'x', 'n', 's' }, '<A-w>', function()
  Snacks.bufdelete()
end, { desc = 'Close Buffer' })
