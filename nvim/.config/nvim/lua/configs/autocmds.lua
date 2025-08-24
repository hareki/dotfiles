-- [[ Autocommands ]]
--  See `:help lua-guide-autocommands`
local function augroup(name)
  return vim.api.nvim_create_augroup(name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

-- Check if we need to reload the file when it changed
aucmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd('checktime')
    end
  end,
})

-- Resize splits if window got resized
aucmd({ 'VimResized' }, {
  group = augroup('resize_splits'),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd('tabdo wincmd =')
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Go to last location when opening a buffer
aucmd('BufReadPost', {
  group = augroup('last_location'),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf

    -- Skip if the filetype is excluded or we've already restored once
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].restored_last_position then
      return
    end

    vim.b[buf].restored_last_position = true -- mark as done

    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
aucmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd('close')
        pcall(vim.api.nvim_buf_delete, event.buf, {
          force = true,
        })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- Make it easier to close man-files when opened inline
aucmd('FileType', {
  group = augroup('man_unlisted'),
  pattern = { 'man' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Fix conceallevel for json files
aucmd({ 'FileType' }, {
  group = augroup('json_conceal'),
  pattern = { 'json', 'jsonc', 'json5' },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd('CmdwinEnter', {
  callback = function()
    -- Use the same keymap as switching to cmdline window mode (vim.opt.cedit) to switch back to cmdline mode
    vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-f>', '<C-c>')

    vim.keymap.set({ 'n' }, 'q', '<cmd>:q!<cr><esc>', {
      silent = true,
    })
  end,
})

local autocommand_group = vim.api.nvim_create_augroup('TabDefaultNames', { clear = true })
vim.api.nvim_create_autocmd('TabEnter', {
  group = autocommand_group,
  callback = function()
    vim.schedule(function()
      local old_name = vim.t.tab_name
      local diffview = require('diffview.lib').get_current_view()
      if diffview then
        vim.t.tab_name = 'Diffview'
      else
        vim.t.tab_name = 'Tab ' .. require('utils.tab').current_tab_index()
      end

      if old_name ~= vim.t.tab_name then
        require('lualine').refresh({ place = { 'statusline' } })
      end
    end)
  end,
})
