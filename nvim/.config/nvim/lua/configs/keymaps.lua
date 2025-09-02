--  See `:help vim.keymap.set()`
local map = vim.keymap.set
local del = vim.keymap.del
map({ 'n' }, 'Q', '<cmd>q<cr>', { desc = 'Close Buffer' })

map({ 'n', 'x' }, '<A-c>', '"+y', { desc = 'Yank to System Clipboard', remap = true })
map({ 'n', 'x' }, '<A-x>', '"+d', { desc = 'Cut to System Clipboard', remap = true })
map({ 'n', 'x' }, '<A-v>', '"+p', { desc = 'Paste from System Clipboard', remap = true })
map({ 'i' }, '<A-v>', '<C-o>"+p', { desc = 'Paste from System Clipboard', remap = true })
map({ 'n' }, '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear Search Highlight' })

map({ 'n', 'i' }, '<A-s>', function()
  require('utils.formatters.async_style_enforcer').run()
end, { desc = 'Format and Save' })

map({ 'i', 'x', 'n', 's' }, '<A-r>', '<cmd>e!<cr>', { desc = 'Reload File', silent = true })

map({ 'n', 'x' }, '<leader>qa', '<cmd>qa!<cr>', { desc = 'Force Quit All', silent = true })
map({ 'n', 'x' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll Up and Center' })
map({ 'n', 'x' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll Down and Center' })

map('v', '<leader>t', "ygvgc']p", {
  remap = true,
  silent = true,
  desc = 'Yank, Comment, Move Below, and Paste',
})
-- Trimmed, No indent/trailing
map('n', 'yy', '^yg_', { desc = 'Yank Line Trimmed' })
map('n', 'dd', function()
  vim.cmd.normal({ args = { [[^dg_]] }, bang = true }) -- delete from first nonblank to last nonblank
  vim.cmd.normal({ args = { [["_dd]] }, bang = true }) -- remove remaining indent + newline (blackhole)
end, { desc = 'Delete Line Trimmed' })

-- Better indenting
map('v', '<', '<gv', { desc = 'Indent Left' })
map('v', '>', '>gv', { desc = 'Indent Right' })

-- Better up/down
map(
  { 'n', 'x' },
  '<Down>',
  "v:count == 0 ? 'gj' : 'j'",
  { desc = 'Down', expr = true, silent = true }
)
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Open Lazy' })
map('n', '<leader>-', '<C-W>s', { desc = 'Split Window Below', remap = true })
map('n', '<leader>\\', '<C-W>v', { desc = 'Split Window Right', remap = true })

local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
map('n', '[d', diagnostic_goto(false), { desc = 'Previous Diagnostic' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Previous Error' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Previous Warning' })
map('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
map('n', ']B', '<cmd>blast<cr>', { desc = 'Last Buffer' })
map('n', '[b', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
map('n', '[B', '<cmd>brewind<cr>', { desc = 'First Buffer' })
map('n', ']t', '<cmd>tabnext<cr>', { desc = 'Next Tab' })
map('n', ']T', '<cmd>tablast<cr>', { desc = 'Last Tab' })
map('n', '[t', '<cmd>tabprevious<cr>', { desc = 'Previous Tab' })
map('n', '[T', '<cmd>tabrewind<cr>', { desc = 'First Tab' }) -- or tabfirst

-- Clean up keymaps picker a little
del('n', ']a')
del('n', '[a')
del('n', '[A')
del('n', ']A')
del('n', ']l')
del('n', '[l')
del('n', ']L')
del('n', '[L')
del('n', ']Q')
del('n', '[Q')
del('n', ']<C-L>')
del('n', '[<C-L>')
del('n', ']<C-Q>')
del('n', '[<C-Q>')
del('n', ']<C-T>')
del('n', '[<C-T>')

map('n', '<leader>tn', '<cmd>tabnew<cr>', { desc = 'New Tab' })
map('n', '<leader>t]', '<cmd>tabnext<cr>', { desc = 'Next Tab' })
map('n', '<leader>t[', '<cmd>tabprevious<cr>', { desc = 'Previous Tab' })
map('n', '<leader>td', '<cmd>tabclose<cr>', { desc = 'Close Tab' })
map('n', '<leader>tr', function()
  vim.ui.input({ prompt = 'Tab name: ' }, function(input)
    if input and input ~= '' then
      vim.cmd('TabRename ' .. input)
    end
  end)
end, { desc = 'Rename tab' })

-- map({ 'n', 'x' }, '<leader>T', function()
-- local progress = require('utils.progress').create({
--   pending_ms = 0,
--   client_name = 'stenfo',
-- })
-- progress:start('test')

-- notifier.info('Find files: **test**')
-- notifier.warn({
--   { 'Added ', 'Normal' },
--   { 'Test', 'NotifyWARNTitle' },
-- }, { title = 'harpoon' })
-- end, { desc = 'Test' })
