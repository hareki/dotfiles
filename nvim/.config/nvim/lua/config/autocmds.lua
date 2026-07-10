-- [[ Autocommands ]]
local function augroup(name)
  return vim.api.nvim_create_augroup('config.autocmds.' .. name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

-- Check if we need to reload the file when it changed
aucmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.bo.buftype ~= 'nofile' then
      vim.cmd.checktime()
    end
  end,
})

-- Resize splits if window got resized
aucmd({ 'VimResized' }, {
  group = augroup('resize-splits'),
  callback = function()
    local current_tab = vim.api.nvim_get_current_tabpage()

    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
      vim.api.nvim_set_current_tabpage(tabpage)
      vim.cmd.wincmd({ args = { '=' } })
    end

    vim.api.nvim_set_current_tabpage(current_tab)
  end,
})

-- Go to last location when opening a buffer
aucmd('BufReadPost', {
  group = augroup('last-location'),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf

    -- Skip if the filetype is excluded or we've already restored once
    if vim.list_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].restored_last_position then
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
  group = augroup('close-with-q'),
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
    'eslint-log',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', function()
      pcall(vim.api.nvim_win_close, 0, true)
      pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
    end, {
      buffer = event.buf,
      desc = 'Quit Buffer',
    })
  end,
})

-- Restore native <CR> (jump to entry) in quickfix/loclist windows, which the
-- global 'Insert Newline after Cursor' <CR> map would otherwise shadow
aucmd('FileType', {
  group = augroup('qf-native-enter'),
  pattern = { 'qf' },
  callback = function(event)
    vim.keymap.set('n', '<CR>', '<CR>', {
      buffer = event.buf,
      desc = 'Jump to Entry',
    })
  end,
})

-- Open help vertically to the right
aucmd('FileType', {
  group = augroup('help-right'),
  pattern = { 'help' },
  command = 'wincmd L',
})

-- Stop starting auto comment insertion on new lines
aucmd('FileType', {
  group = augroup('stop-auto-comment'),
  pattern = '*',
  callback = function()
    vim.opt_local.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- Make it easier to close man-files when opened inline
aucmd('FileType', {
  group = augroup('man-unlisted'),
  pattern = { 'man' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Fix conceallevel for json files
aucmd({ 'FileType' }, {
  group = augroup('json-conceal'),
  pattern = Conf.filetypes.JSON,
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

aucmd('FileType', {
  group = augroup('markdown-defaults'),
  pattern = { 'markdown' },
  callback = function()
    vim.wo.wrap = true
  end,
})

-- Use the same keymap as switching to cmdline window mode (vim.opt.cedit) to switch back to cmdline mode
aucmd('CmdwinEnter', {
  group = augroup('cmdwin-keymaps'),
  callback = function(event)
    local buf = event.buf

    vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-f>', '<C-c>', {
      buffer = buf,
      desc = 'Exit Command-Line Window Mode',
    })

    vim.keymap.set({ 'n' }, 'q', '<cmd>q!<cr>', {
      buffer = buf,
      desc = 'Quit Command-Line Window',
    })

    -- Restore native <CR> (execute the selected command), which the global
    -- 'Insert Newline after Cursor' <CR> map would otherwise shadow
    vim.keymap.set('n', '<CR>', '<CR>', {
      buffer = buf,
      desc = 'Execute Command',
    })
  end,
})

-- Close all codediff tabs on exit so that auto-session doesn't save them
aucmd('VimLeavePre', {
  group = augroup('close-codediff-tabs-on-exit'),
  callback = function()
    -- codediff is lazy; if it never loaded there are no diff tabs to close.
    local package = require('utils.package')
    if not package.is_loaded('codediff.nvim') then
      return
    end

    local lifecycle = require('codediff.ui.lifecycle')
    local codediff_tabs = {}

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if lifecycle.get_session(tab) then
        table.insert(codediff_tabs, tab)
      end
    end

    for _, tab in ipairs(codediff_tabs) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        pcall(vim.api.nvim_set_current_tabpage, tab)
        vim.cmd.tabclose({ mods = { silent = true } })
      end
    end
  end,
})

-- Clear search highlight when entering insert mode
aucmd('InsertEnter', {
  group = augroup('clear-hlsearch-on-insert'),
  callback = function()
    if vim.v.hlsearch == 1 then
      vim.schedule(function()
        local search_highlight = require('services.search-highlight')
        search_highlight.clear_search_highlight()
      end)
    end
  end,
})

local SNIPPET_STOP_DELAY_MS = 20

aucmd('ModeChanged', {
  group = augroup('stop-snippet-on-normal-mode'),
  pattern = '[is]:n', -- Stricter: only exact 'i' or 's' to 'n'
  desc = 'Stop Snippet Session in Normal Mode',
  callback = function()
    -- Defer the stop to avoid interfering with blink.cmp juggling between modes internally
    vim.defer_fn(function()
      local mode = vim.api.nvim_get_mode().mode
      -- Are we still in normal-like mode after a short delay?
      if mode:sub(1, 1) ~= 'n' then
        return
      end

      if vim.snippet.active() then
        vim.snippet.stop()
      end
    end, SNIPPET_STOP_DELAY_MS)
  end,
})

-- Prevent accidental jumplist navigation in non-file buffers
aucmd('BufEnter', {
  group = augroup('disable-ctrl-o-non-file'),
  callback = function(event)
    local buf = event.buf
    local buftype = vim.bo[buf].buftype

    if buftype ~= '' then
      vim.keymap.set('n', '<C-o>', '<Nop>', {
        buffer = buf,
        desc = 'Disable Jumplist Back in Non-File Buffers',
      })

      vim.keymap.set('n', '<C-i>', '<Nop>', {
        buffer = buf,
        desc = 'Disable Jumplist Forward in Non-File Buffers',
      })
    end
  end,
})
