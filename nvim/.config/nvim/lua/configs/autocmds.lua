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
    'eslint-log',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', function()
      vim.cmd('close')
      pcall(vim.api.nvim_buf_delete, event.buf, {
        force = true,
      })
    end, {
      buffer = event.buf,
      silent = true,
      desc = 'Quit Buffer',
    })
  end,
})

-- Open help vertically to the right
aucmd('FileType', {
  group = augroup('help_right'),
  pattern = { 'help' },
  command = 'wincmd L',
})

-- Stop starting auto comment insertion on new lines
aucmd('FileType', {
  group = augroup('stop_auto_comment'),
  pattern = '*',
  callback = function()
    vim.opt_local.formatoptions:remove({ 'c', 'r', 'o' })
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

aucmd('FileType', {
  group = augroup('markdown_defaults'),
  pattern = { 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- Use the same keymap as switching to cmdline window mode (vim.opt.cedit) to switch back to cmdline mode
aucmd('CmdwinEnter', {
  callback = function(event)
    local buf = event.buf

    vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-f>', '<C-c>', {
      buffer = buf,
      silent = true,
      desc = 'Exit Command-Line Window Mode',
    })

    vim.keymap.set({ 'n' }, 'q', '<CMD>:q!<CR><Esc>', {
      buffer = buf,
      silent = true,
      desc = 'Quit Command-Line Window',
    })
  end,
})

-- Refresh lualine tab names on TabEnter
if require('plugins.ui.lualine.utils').have_status_line() then
  aucmd('TabEnter', {
    group = augroup('tab_watchers'),
    callback = function()
      vim.schedule(function()
        local old_name = vim.t.tab_name
        vim.t.tab_name = require('utils.tab').get_tab_name()

        if old_name ~= vim.t.tab_name and package.loaded['lualine'] then
          require('lualine').refresh({ place = { 'statusline' } })
        end
      end)
    end,
  })
end

-- Close all diffview tabs on exit so that auto-session doesn't save them
aucmd('VimLeavePre', {
  group = augroup('close_diffview_tabs_on_exit'),
  callback = function()
    local diffview_tabs = {}
    local prefix = 'diffview-tab'

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local tab_vars = vim.t[tab]
      local name = tab_vars and tab_vars.tab_name

      if type(name) == 'string' and name:sub(1, #prefix) == prefix then
        table.insert(diffview_tabs, tab)
      end
    end

    for _, tab in ipairs(diffview_tabs) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        pcall(vim.api.nvim_set_current_tabpage, tab)
        vim.cmd('silent! tabclose')
      end
    end
  end,
})

-- Clear search highlight when entering insert mode
aucmd('InsertEnter', {
  callback = function()
    if vim.v.hlsearch == 1 then
      vim.schedule(function()
        vim.cmd('nohlsearch')
      end)
    end
  end,
})

aucmd('ModeChanged', {
  group = augroup('stop_snippet_on_normal_mode'),
  -- pattern = '[is]*:n*', -- Only fire when leaving Insert/Select-like modes for Normal(-like) modes
  pattern = '[is]:n', -- Stricter version
  desc = 'Stop vim.snippet session when actually ending in Normal mode',
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
    end, 20)
  end,
})

-- Prevent accidental jumplist navigation in non-file buffers
aucmd('BufEnter', {
  group = augroup('disable_ctrl_o_non_file'),
  callback = function(event)
    local buf = event.buf
    local buftype = vim.bo[buf].buftype

    if buftype ~= '' then
      vim.keymap.set('n', '<C-o>', '<Nop>', {
        buffer = buf,
        silent = true,
        desc = 'Disabled Jumplist Back in Non-file Buffers',
      })

      vim.keymap.set('n', '<C-i>', '<Nop>', {
        buffer = buf,
        silent = true,
        desc = 'Disabled Jumplist Forward in Non-file Buffers',
      })
    end
  end,
})
