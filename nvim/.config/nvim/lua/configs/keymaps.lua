local del = vim.keymap.del
local map = vim.keymap.set

local function diagnostic_goto(next, severity)
  local count = next and 1 or -1
  severity = severity and vim.diagnostic.severity[severity] or nil

  return function()
    vim.diagnostic.jump({ severity = severity, float = false, count = count })
    vim.schedule(function()
      vim.cmd.EagleWinLineDiagnostic()
    end)
  end
end

-- Clean up Snacks keymaps picker a little
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

map({ 'n' }, 'Q', '<CMD>q<CR>', { desc = 'Close Buffer' })
map('n', '<CR>', 'a<CR><Esc>', { desc = 'Break Line After Cursor' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Leave Terminal Mode' })

map({ 'n' }, '<Esc>', function()
  vim.cmd.nohlsearch()
  vim.snippet.stop()
end, { desc = 'Clear Highlight' })

map({ 'n', 'i' }, '<A-s>', function()
  require('utils.formatters.async_style_enforcer').run()
end, { desc = 'Format and Save' })

map({ 'n', 'i' }, '<leader>F', function()
  require('utils.formatters.async_style_enforcer').run({
    save = false,
  })
end, { desc = 'Format' })

-- Mapped to Ctrl+Shift+S in ghostty config
-- Test the keymap Neovim will receive with
-- :echo keytrans(getcharstr())
map({ 'n', 'i' }, '<F40>', function()
  require('utils.formatters.async_style_enforcer').run_all()
end, { desc = 'Format and Save All' })

-- Mapped to Ctrl+Shift+W in ghostty config
-- Test the keymap Neovim will receive with
-- :echo keytrans(getcharstr())
map({ 'i', 'x', 'n', 's' }, '<C-S-End>', function()
  Snacks.bufdelete.other()
  Notifier.info('Closed Other Buffers')
end, { desc = 'Close Other Buffers' })

map({ 'n', 'x' }, '<leader>qa', '<CMD>qa<CR>', { desc = 'Quit All' })
map({ 'n', 'x' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll Up and Center' })
map({ 'n', 'x' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll Down and Center' })

map('v', '<leader>t', "ygvgc']p", {
  remap = true,
  desc = 'Yank, Comment, Move Below, and Paste',
})

map('n', '<leader>?h', '<CMD>HlAtCursor<CR>', {
  desc = 'Highlight Groups at Cursor',
})

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

map('n', '<leader>l', '<CMD>Lazy<CR>', { desc = 'Lazy.nvim' })
map('n', '<leader>-', '<C-W>s', { desc = 'Split Window Below', remap = true })
map('n', '<leader>\\', '<C-W>v', { desc = 'Split Window Right', remap = true })

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
map('n', ']b', '<CMD>bnext<CR>', { desc = 'Next Buffer' })
map('n', ']B', '<CMD>blast<CR>', { desc = 'Last Buffer' })
map('n', '[b', '<CMD>bprevious<CR>', { desc = 'Previous Buffer' })
map('n', '[B', '<CMD>brewind<CR>', { desc = 'First Buffer' })

map({ 'i', 'x', 'n', 's' }, '<A-r>', '<CMD>e!<CR>', { desc = 'Reload File', silent = true })
map({ 'i', 'x', 'n', 's' }, '<A-w>', function()
  Snacks.bufdelete()
end, { desc = 'Close Buffer' })
