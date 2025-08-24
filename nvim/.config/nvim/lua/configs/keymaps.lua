--  See `:help vim.keymap.set()`
local map = vim.keymap.set
map({ 'n' }, 'Q', '<cmd>q<cr>', { desc = 'Close buffer' })

map({ 'n', 'x' }, '<A-c>', '"+y', { desc = 'Yank to system clipboard', remap = true })
map({ 'n', 'x' }, '<A-x>', '"+d', { desc = 'Cut to system clipboard', remap = true })
map({ 'n', 'x' }, '<A-v>', '"+p', { desc = 'Paste from system clipboard', remap = true })
map({ 'i' }, '<A-v>', '<C-o>"+p', { desc = 'Paste from system clipboard', remap = true })

map({ 'n', 'i' }, '<A-s>', function()
  require('utils.formatters.async_style_enforcer').run()
end, { desc = 'Format (Prettier) + ESLint Fix All + Save' })

map({ 'i', 'x', 'n', 's' }, '<A-r>', '<cmd>e!<cr>', { desc = 'Reload file', silent = true })

map({ 'n', 'x' }, '<leader>qa', '<cmd>qa!<cr>', { desc = 'Force quit all', silent = true })
map({ 'n', 'x' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll up and center' })
map({ 'n', 'x' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll down and center' })

map('x', 'x', '"0d', { desc = 'Cut to register 0' })

map('v', '<leader>t', "ygvgc']p", {
  remap = true,
  silent = true,
  desc = 'Yank, comment, move below, and paste',
})

-- Better indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Better up/down
map(
  { 'n', 'x' },
  '<Down>',
  "v:count == 0 ? 'gj' : 'j'",
  { desc = 'Down', expr = true, silent = true }
)
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

map('n', '<leader>l', '<cmd>Lazy<cr>', { desc = 'Lazy' })
map('n', '<leader>-', '<C-W>s', { desc = 'Split window below', remap = true })
map('n', '<leader>\\', '<C-W>v', { desc = 'Split window right', remap = true })

local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
map('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })

map('n', '<leader>T', function()
  notifier.info('Find files: **test**')
  notifier.warn({
    { 'Added ', 'Normal' },
    { 'Test', 'NotifyWARNTitle' },
  }, { title = 'harpoon' })
end, { desc = 'Test' })
