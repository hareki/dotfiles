--  See `:help vim.keymap.set()`
local map = vim.keymap.set
local del = vim.keymap.del
map({ 'n' }, 'Q', '<CMD>q<CR>', { desc = 'Close Buffer' })

map({ 'n' }, '<Esc>', '<CMD>nohlsearch<CR>', { desc = 'Clear Search Highlight' })

map({ 'n', 'i' }, '<A-s>', function()
  require('utils.formatters.async_style_enforcer').run()
end, { desc = 'Format and Save' })

map({ 'i', 'x', 'n', 's' }, '<A-r>', '<CMD>e!<CR>', { desc = 'Reload File', silent = true })

map({ 'n', 'x' }, '<leader>qa', '<CMD>qa!<CR>', { desc = 'Force Quit All', silent = true })
map({ 'n', 'x' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll Up and Center' })
map({ 'n', 'x' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll Down and Center' })

map('v', '<leader>t', "ygvgc']p", {
  remap = true,
  silent = true,
  desc = 'Yank, Comment, Move Below, and Paste',
})

map('n', '<leader>?h', '<CMD>HlAtCursor<CR>', {
  remap = true,
  silent = true,
  desc = 'Highlight Groups at Cursor',
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

map('n', '<leader>l', '<CMD>Lazy<CR>', { desc = 'Open Lazy' })
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
map('n', ']b', '<CMD>bnext<CR>', { desc = 'Next Buffer' })
map('n', ']B', '<CMD>blast<CR>', { desc = 'Last Buffer' })
map('n', '[b', '<CMD>bprevious<CR>', { desc = 'Previous Buffer' })
map('n', '[B', '<CMD>brewind<CR>', { desc = 'First Buffer' })
map('n', ']t', '<CMD>tabnext<CR>', { desc = 'Next Tab' })
map('n', ']T', '<CMD>tablast<CR>', { desc = 'Last Tab' })
map('n', '[t', '<CMD>tabprevious<CR>', { desc = 'Previous Tab' })
map('n', '[T', '<CMD>tabrewind<CR>', { desc = 'First Tab' }) -- or tabfirst

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

map('n', '<leader>tn', '<CMD>tabnew<CR>', { desc = 'New Tab' })
map('n', '<leader>t]', '<CMD>tabnext<CR>', { desc = 'Next Tab' })
map('n', '<leader>t[', '<CMD>tabprevious<CR>', { desc = 'Previous Tab' })
map('n', '<leader>td', '<CMD>tabclose<CR>', { desc = 'Close Tab' })
map('n', '<leader>tr', function()
  vim.ui.input({ prompt = 'Rename the Tab' }, function(input)
    if input and input ~= '' then
      vim.cmd('TabRename ' .. input)
    end
  end)
end, { desc = 'Rename Tab' })

map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave Terminal Mode' })

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
