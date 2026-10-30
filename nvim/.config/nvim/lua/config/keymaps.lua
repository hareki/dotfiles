local keymap_registry = require('config.keymap-registry')

local del = vim.keymap.del
local map = vim.keymap.set

--- @module 'utils.style-enforcers'
local style_enforcers = Defer.on_exported_call('utils.style-enforcers')

local function diagnostic_goto(next, severity)
  local direction = next and 1 or -1
  severity = vim.diagnostic.severity[severity]

  return function()
    vim.diagnostic.jump({ severity = severity, count = direction * vim.v.count1 })
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
  ']T',
  '[T',
  ']<C-L>',
  '[<C-L>',
  ']<C-Q>',
  '[<C-Q>',
  ']<C-T>',
  '[<C-T>',
}) do
  pcall(del, 'n', key)
end

-- Retitle Neovim's own maps in place: which-key and the keymaps picker read the desc off the map,
-- while a buffer-local map on the same key (the gO outline in help, markdown and man) keeps its own
local retitles = {}
for lhs, spec in pairs(keymap_registry.DESC_OVERRIDES) do
  for _, mode in ipairs(spec.mode or { 'n' }) do
    retitles[mode] = retitles[mode] or {}
    -- Compared as keytrans() text: registry keys spell <leader>, lhsraw keeps <C-S> unsimplified
    retitles[mode][vim.fn.keytrans(vim.keycode(lhs))] = spec.desc
  end
end
for mode, descs in pairs(retitles) do
  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    local desc = descs[vim.fn.keytrans(keymap.lhsraw)]
    if desc then
      keymap.desc = desc
      vim.fn.mapset(mode, false, keymap)
    end
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

map({ 'n', 'i' }, '<A-s>', style_enforcers.run, { desc = 'Format and Save' })

map('n', '<leader>F', function()
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

-- Diagnostics: every jump opens the line's diagnostics, Neovim's own count-aware ]d/[d/]D/[D
-- included; on_jump runs scheduled, and only once the jump succeeded
vim.diagnostic.config({
  jump = {
    on_jump = function()
      vim.cmd.EagleWinLineDiagnostic()
    end,
  },
})
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Previous Error' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Previous Warning' })
map('n', ']i', diagnostic_goto(true, 'INFO'), { desc = 'Next Info' })
map('n', '[i', diagnostic_goto(false, 'INFO'), { desc = 'Previous Info' })

-- Buffer (Neovim's own ]b/[b/]B/[B take counts; config/keymap-registry.lua titles them)
map(
  { 'i', 'x', 'n', 's' },
  '<A-r>',
  '<cmd>edit!<cr>',
  { desc = 'Reload Current Buffer', silent = true }
)

map({ 'i', 'x', 'n', 's' }, '<A-w>', function()
  Snacks.bufdelete()
end, { desc = 'Close Buffer' })
