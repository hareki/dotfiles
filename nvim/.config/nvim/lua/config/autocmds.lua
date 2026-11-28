local function augroup(name)
  return vim.api.nvim_create_augroup('config.autocmds.' .. name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

--- @module 'utils.keymap'
local keymap = Defer.on_exported_call('utils.keymap')

-- Reload files changed on disk; bare `:checktime` skips hidden buffers (contra its docs)
aucmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    -- Scheduled: `:checktime {bufnr}` skips the bare form's wait for a harmless moment in autocmds
    vim.schedule(function()
      -- A reload rewrites the buffer's undo file, and that flush takes a third of the reload
      local fsync = vim.go.fsync
      vim.go.fsync = false

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        -- getbufvar, since vim.bo switches into the autocmd window (~10us per read, against ~0.2us)
        if
          vim.api.nvim_buf_is_loaded(bufnr)
          and vim.fn.getbufvar(bufnr, '&buftype') == ''
          and vim.fn.getbufvar(bufnr, '&modified') == 0
          and vim.api.nvim_buf_get_name(bufnr) ~= ''
        then
          -- `silent!`: a file that no longer exists (branch switch, agent deletion) reports E211
          vim.cmd('silent! checktime ' .. bufnr)
        end
      end

      vim.go.fsync = fsync
    end)
  end,
})

-- Equalize splits on resize. Background tabpages refit only once entered, so they wait for
-- TabEnter: visiting them here would fire Win/BufEnter and retarget focus trackers (lazygit's)
local resize_group = augroup('resize-splits')
--- @type table<integer, true>
local tabpages_to_equalize = {}

aucmd({ 'VimResized' }, {
  group = resize_group,
  callback = function()
    -- Every background tabpage is re-marked below, which also drops closed tabpages' handles
    tabpages_to_equalize = {}

    local current_tabpage = vim.api.nvim_get_current_tabpage()
    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
      if tabpage ~= current_tabpage then
        tabpages_to_equalize[tabpage] = true
      end
    end

    -- Equalizing would stretch an open cmdline window past its 'cmdwinheight'
    if vim.fn.win_gettype() == 'command' then
      return
    end

    vim.cmd.wincmd('=')
  end,
})

aucmd('TabEnter', {
  group = resize_group,
  callback = function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    if tabpages_to_equalize[tabpage] then
      tabpages_to_equalize[tabpage] = nil
      vim.cmd.wincmd('=')
    end
  end,
})

-- Read binary files raw (git's test: a NUL in the first 8000 bytes), or :w re-encodes them per
-- editorconfig's `charset` and appends an EOL; UTF-16 has NULs too, but its BOM gets it decoded
aucmd('BufReadPre', {
  group = augroup('binary-files'),
  callback = function(event)
    -- Regular files only: opening a FIFO would wait for its writer
    local stat = vim.uv.fs_stat(event.match)
    local fd = stat and stat.type == 'file' and vim.uv.fs_open(event.match, 'r', 438)
    if not fd then
      return
    end
    local head = vim.uv.fs_read(fd, 8000, 0) or ''
    vim.uv.fs_close(fd)

    local bom = head:sub(1, 2)
    if head:find('\0', 1, true) and bom ~= '\254\255' and bom ~= '\255\254' then
      vim.bo[event.buf].binary = true
      -- Its whitespace and final-newline rules would still rewrite the bytes on :w
      vim.b[event.buf].editorconfig = false
    end
  end,
})

-- Restore the last cursor position on BufWinEnter, as BufReadPost runs ahead of filetypedetect;
-- a hidden bufload() would spend the mark in the autocmd window, where this event fires too
aucmd('BufWinEnter', {
  group = augroup('last-location'),
  callback = function(event)
    local buf = event.buf

    if
      vim.b[buf].restored_last_position
      or vim.bo[buf].filetype == 'gitcommit'
      or vim.fn.win_gettype() == 'autocmd'
    then
      return
    end

    vim.b[buf].restored_last_position = true

    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Unlist these utility buffers and close them with `q`
aucmd('FileType', {
  group = augroup('close-with-q'),
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'gitsigns-blame',
    'grug-far',
    'help',
    'notify',
    'qf',
  },
  callback = function(event)
    -- A help file opened for editing (a plugin's `doc/*.txt`, buftype '') is a file like any other:
    -- this `q` would throw its unsaved edits away
    if event.match == 'help' and vim.bo[event.buf].buftype ~= 'help' then
      return
    end

    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', function()
      pcall(vim.api.nvim_win_close, 0, true)
      pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
    end, {
      buf = event.buf,
      desc = 'Quit Buffer',
    })
  end,
})

-- Open help vertically to the right; a help file opened for editing (buftype '') stays in place
aucmd('FileType', {
  group = augroup('help-right'),
  pattern = { 'help' },
  callback = function(event)
    if vim.bo[event.buf].buftype == 'help' then
      vim.cmd.wincmd('L')
    end
  end,
})

-- Don't continue comments onto new lines
aucmd('FileType', {
  group = augroup('stop-auto-comment'),
  callback = function()
    vim.opt_local.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- Switch back to the cmdline with the key that opened the cmdline window ('cedit')
aucmd('CmdwinEnter', {
  group = augroup('cmdwin-keymaps'),
  callback = function(event)
    local map = keymap.buf_mapper(event.buf)
    map({ 'i', 'x', 'n', 's' }, '<C-f>', '<C-c>', 'Exit Command-Line Window Mode')
    map('n', 'q', '<cmd>q!<cr>', 'Quit Command-Line Window')
  end,
})

-- Clear search highlights on insert; scheduled, as autocmds restore the hlsearch state
aucmd('InsertEnter', {
  group = augroup('clear-hlsearch-on-insert'),
  callback = function()
    vim.schedule(UI.search.clear)
  end,
})

-- Pass a terminal program's status reports (OSC 7501) on to the Rex pane, since nvim's terminal
-- drops them. Claude Code reports only once the terminal has answered its query
local program_status_group = augroup('program-status')
--- Per terminal buffer, the state its program reported last for the root record
--- @type table<integer, string>
local reported_states = {}

aucmd('TermRequest', {
  group = program_status_group,
  callback = function(event)
    local report = event.data.sequence:match('^\27%]7501;(.*)')
    if not report or not vim.env.REX_BLOCK then
      return
    end

    if report == '?' then
      -- The answer of a terminal that takes the protocol's own states and kinds
      vim.api.nvim_chan_send(vim.bo[event.buf].channel, '\27]7501;?\27\\')
      return
    end

    -- A report with an `id` is for a child record (a sub-agent's): the root record stays as it
    -- was, and the clear at its program's end takes the child records too
    if not (':' .. report):find(':id=', 1, true) then
      reported_states[event.buf] = (':' .. report):match(':state=(%l+)')
    end
    -- Through the TUI's own output, so the sequence never lands inside one the TUI is writing
    vim.api.nvim_ui_send(event.data.sequence .. '\27\\')
  end,
})

-- The pane drops such a record only when nvim ends, so clear one its program left up on ending
-- here (killed, its buffer wiped). `done` and `error` outlast their program
aucmd('TermClose', {
  group = program_status_group,
  callback = function(event)
    local state = reported_states[event.buf]
    reported_states[event.buf] = nil
    if state == 'working' or state == 'blocked' or state == 'idle' then
      vim.api.nvim_ui_send('\27]7501;state=clear\27\\')
    end
  end,
})
