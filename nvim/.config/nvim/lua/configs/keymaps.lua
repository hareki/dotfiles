--  See `:help vim.keymap.set()`
local map = vim.keymap.set
map({ 'n' }, 'Q', '<cmd>q<cr>', { desc = 'Close buffer' })

map({ 'n', 'x' }, '<A-c>', '"+y', { desc = 'Yank to system clipboard', remap = true })
map({ 'n', 'x' }, '<A-x>', '"+d', { desc = 'Cut to system clipboard', remap = true })
map({ 'n', 'x' }, '<A-v>', '"+p', { desc = 'Paste from system clipboard', remap = true })
map({ 'i' }, '<A-v>', '<C-o>"+p', { desc = 'Paste from system clipboard', remap = true })

local function async_style_enforce()
  local conform = require('conform')
  local buf = vim.api.nvim_get_current_buf()

  local progress = require('utils.progress').create({
    pending_ms = 0,
    client_name = 'stenfo',
  })

  progress:start('Formatting')

  conform.format({
    async = true,
    bufnr = buf,
  }, function(err)
    if err then
      vim.notify('Prettier error: ' .. err, vim.log.levels.ERROR)
      return
    end

    local total = #linters.names_for_filetype(vim.bo[buf].filetype) + 1 -- Formater is already done
    local done_count = 1
    local percentage = 100 / total

    linters.run_by_ft({
      bufnr = buf,
      on_start = function(name)
        progress:report('Linting (' .. name .. ')', percentage * done_count)
      end,
      on_done = function(name, ok, lerr)
        if not ok and lerr then
          vim.notify(('%s failed: %s'):format(name, lerr), vim.log.levels.WARN)
        end
        done_count = done_count + 1
        if done_count == total then
          if vim.bo[buf].modified then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd.write()
            end)
          end

          progress:finish()
        end
      end,
    })
  end)
end

vim.keymap.set({ 'n', 'i' }, '<A-s>', function()
  async_style_enforce()
end, { desc = 'Format (Prettier) + ESLint Fix All + Save' })

map({ 'i', 'x', 'n', 's' }, '<A-r>', '<cmd>e!<cr>', { desc = 'Reload file', silent = true })

map({ 'n', 'v' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll up and center' })
map({ 'n', 'v' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll down and center' })
map('x', 'x', '"0d', { desc = 'Cut to register 0' })
map('v', '<leader>t', 'ygvgcp', { remap = true, silent = true, desc = 'Yank, comment and paste' })

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
