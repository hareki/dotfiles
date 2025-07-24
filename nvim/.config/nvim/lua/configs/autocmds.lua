-- [[ Autocommands ]]
--  See `:help lua-guide-autocommands`
local function augroup(name)
  return vim.api.nvim_create_augroup(name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

local function disable_doc_hl()
  require('utils.ui').set_highlights({
    LspReferenceRead = {
      bg = 'none',
    },
    LspReferenceText = {
      bg = 'none',
    },
    LspReferenceWrite = {
      bg = 'none',
    },
  })
end

local function enable_doc_hl()
  require('utils.ui').set_highlights({
    LspReferenceRead = {
      link = 'DocumentHighlight',
    },
    LspReferenceText = {
      link = 'DocumentHighlight',
    },
    LspReferenceWrite = {
      link = 'DocumentHighlight',
    },
  })
end

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
    'spectre_panel',
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

-- Highlight all occurrences of selected text in visual mode
-- https://github.com/Losams/-VIM-Plugins/blob/master/checkSameTerm.vim
vim.g.checking_same_term = 0
aucmd({ 'CursorMoved', 'ModeChanged' }, {
  pattern = '*',
  -- Function to check the same term
  callback = function()
    local currentmode = vim.api.nvim_get_mode().mode
    -- Check for any visual mode
    if currentmode == 'v' or currentmode == 'V' or currentmode == '\22' then
      vim.g.checking_same_term = 1
      -- Backing up what we're having in the register
      local s = vim.fn.getreg('"')

      -- Get currently selected text by yanking them into the register
      vim.cmd('silent! normal! ygv')
      local search_term = vim.fn.getreg('"')
      search_term = vim.fn.escape(search_term, '\\/'):gsub('\n', '\\n')
      -- Check if the search term is not just blank space or newline characters
      if search_term:match('^%s*$') == nil and search_term:match('^\\n*$') == nil then
        vim.cmd('match DocumentHighlight /\\V' .. search_term .. '/')
      else
        vim.cmd('match none')
      end

      -- Restore the text back to the register after searching
      vim.fn.setreg('"', s)
      vim.g.checking_same_term = 0
    else
      vim.cmd('match none')
    end
  end,
})

-- Different yank colors based on the register name
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua#L17-L23
aucmd('TextYankPost', {
  group = augroup('highlight_yank'),
  callback = function()
    -- Ensure yank-related events are processed first
    -- tiny-inline-diagnostic prevent the highlight on yank to work properly so we need to temporarily disable it during the highlight
    vim.defer_fn(function()
      -- require("tiny-inline-diagnostic").disable()
      disable_doc_hl()
    end, 50)

    local register = vim.v.event.regname
    if vim.g.checking_same_term == 0 then
      if register == '+' or register == '*' then
        vim.highlight.on_yank({
          higroup = 'SystemYankHighlight',
        })
      else
        vim.highlight.on_yank({
          higroup = 'RegisterYankHighlight',
        })
      end
    end
    -- vim.highlight.on_yank({ higroup = "YankRegisterHighlight" })

    -- Wait for the highlight to wear out before re-enabling it (default duration = 150ms, we wait for an extra 50ms just in case)
    vim.defer_fn(function()
      -- require("tiny-inline-diagnostic").enable()
      if vim.b.visual_multi == nil then
        enable_doc_hl()
      end
    end, require('configs.common').PUT_HL_TIMER + 50)
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
