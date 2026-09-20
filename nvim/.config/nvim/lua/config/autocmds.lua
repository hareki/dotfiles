-- [[ Autocommands ]]
local function augroup(name)
  return vim.api.nvim_create_augroup('config.autocmds.' .. name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

-- Reload files changed on disk. Bare `:checktime` only inspects buffers shown
-- in a window (check_timestamps() skips b_nwindows == 0, contra its docs), so
-- hidden buffers rewritten from outside keep serving stale text.
aucmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    -- `:checktime {bufnr}` reloads immediately, while the argument-less form
    -- postpones the reload to a harmless moment when called from an autocmd.
    -- Deferring to the event loop restores that guarantee.
    vim.schedule(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local bo = vim.bo[bufnr]

        if
          vim.api.nvim_buf_is_loaded(bufnr)
          and bo.buftype == ''
          and not bo.modified
          and vim.api.nvim_buf_get_name(bufnr) ~= ''
        then
          -- `silent!` on top of `pcall`: a file that no longer exists (branch
          -- switch, agent deletion) *reports* E211 instead of raising it
          pcall(function()
            vim.cmd('silent! checktime ' .. bufnr)
          end)
        end
      end
    end)
  end,
})

-- Resize splits if window got resized. Neovim refits a background tabpage to the
-- new screen size only when it's next entered, so those are equalized on TabEnter
-- (which fires after the refit). Visiting them from here would fire Win/BufEnter in
-- each one and retarget focus trackers (e.g. lazygit's last editing window)
local resize_group = augroup('resize-splits')
--- @type table<integer, true>
local tabpages_to_equalize = {}

aucmd({ 'VimResized' }, {
  group = resize_group,
  callback = function()
    -- Every background tabpage is re-marked below, so starting over loses nothing
    -- and drops the handles of tabpages closed while still pending
    tabpages_to_equalize = {}

    local current_tabpage = vim.api.nvim_get_current_tabpage()
    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
      if tabpage ~= current_tabpage then
        tabpages_to_equalize[tabpage] = true
      end
    end

    -- Leave the layout alone while the cmdline window is open: equalizing would
    -- stretch it from its 'cmdwinheight' to an even share of the screen
    if vim.fn.win_gettype() == 'command' then
      return
    end

    vim.cmd.wincmd({ args = { '=' } })
  end,
})

aucmd('TabEnter', {
  group = resize_group,
  callback = function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    if tabpages_to_equalize[tabpage] then
      tabpages_to_equalize[tabpage] = nil
      vim.cmd.wincmd({ args = { '=' } })
    end
  end,
})

-- Go to last location when opening a buffer
aucmd('BufReadPost', {
  group = augroup('last-location'),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf

    -- BufReadPost runs before filetype detection (this autocmd is registered
    -- ahead of filetypedetect), so vim.bo.filetype is still empty here
    local ft = vim.bo[buf].filetype
    if ft == '' then
      ft = vim.filetype.match({ buf = buf }) or ''
    end

    -- Skip if the filetype is excluded or we've already restored once
    if vim.list_contains(exclude, ft) or vim.b[buf].restored_last_position then
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
-- global 'Insert Newline After Cursor' <CR> map would otherwise shadow
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

local markdown_group = augroup('markdown-defaults')
-- Headings as matched by the runtime ftplugin's section jumps
local markdown_heading = [[\%(^#\{1,5\}\s\+\S\|^\S.*\n^[=-]\+$\)]]

aucmd('FileType', {
  group = markdown_group,
  pattern = { 'markdown' },
  callback = function(event)
    -- The runtime ftplugin's visual-mode section jumps, whose own maps are disabled
    -- (see g.no_markdown_maps in config/options.lua)
    vim.keymap.set(
      'x',
      ']]',
      string.format("<cmd>call search('%s', 'sW')<cr>", markdown_heading),
      { buffer = event.buf, desc = 'Jump to Next Section' }
    )
    vim.keymap.set(
      'x',
      '[[',
      string.format("<cmd>call search('%s', 'bsW')<cr>", markdown_heading),
      { buffer = event.buf, desc = 'Jump to Previous Section' }
    )

    local function set_window_options()
      -- Local only: vim.wo also sets the window's global value, which every buffer
      -- opened in (or split from) this window afterwards would inherit
      vim.opt_local.wrap = true
    end

    if vim.fn.win_gettype() ~= 'autocmd' then
      set_window_options()
      return
    end

    -- A buffer loaded while hidden (e.g. an LSP bufload()) gets its FileType, and a
    -- first BufWinEnter, in the temporary autocmd window. FileType won't fire again
    -- once it's displayed for real, so wait for the BufWinEnter of that window
    vim.api.nvim_clear_autocmds({ group = markdown_group, buffer = event.buf })
    aucmd('BufWinEnter', {
      group = markdown_group,
      buffer = event.buf,
      callback = function()
        if vim.fn.win_gettype() ~= 'autocmd' then
          set_window_options()
          return true -- Done, delete this autocmd
        end
      end,
    })
  end,
})

aucmd('FileType', {
  group = augroup('ghostty-defaults'),
  pattern = { 'ghostty' },
  callback = function(event)
    vim.bo[event.buf].commentstring = '# %s'
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
    -- 'Insert Newline After Cursor' <CR> map would otherwise shadow
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
    local codediff_utils = require('features.git.codediff-nvim.utils')
    local codediff_tabs = {}

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if codediff_utils.is_codediff_tab(tab) then
        table.insert(codediff_tabs, tab)
      end
    end

    for _, tab in ipairs(codediff_tabs) do
      if vim.api.nvim_tabpage_is_valid(tab) then
        -- The last tabpage can't be closed (E784); replace it with the file last focused
        -- in codediff. A blank tab would be saved over the cwd session as an empty layout
        if #vim.api.nvim_list_tabpages() == 1 then
          vim.cmd.tabnew()
          codediff_utils.restore_focus_now(tab)
        end
        -- Without the switch, tabclose would close whichever tabpage is current instead
        if pcall(vim.api.nvim_set_current_tabpage, tab) then
          vim.cmd.tabclose({ mods = { silent = true } })
        end
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
        UI.color.nohlsearch()
      end)
    end
  end,
})

local SNIPPET_STOP_DELAY_MS = 20

-- Stop snippet session in Normal mode
aucmd('ModeChanged', {
  group = augroup('stop-snippet-on-normal-mode'),
  pattern = '[is]:n', -- Stricter: only exact 'i' or 's' to 'n'
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
