local function augroup(name)
  return vim.api.nvim_create_augroup('config.autocmds.' .. name, {
    clear = true,
  })
end

local aucmd = vim.api.nvim_create_autocmd

--- @module 'utils.common'
local common = Defer.on_exported_call('utils.common')

-- Reload files changed on disk. Bare `:checktime` skips buffers not shown in a window (contra its
-- docs), so hidden buffers rewritten from outside would keep serving stale text
aucmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    -- `:checktime {bufnr}` reloads immediately, unlike the bare form, which waits for a harmless
    -- moment when called from an autocmd; scheduling restores that guarantee
    vim.schedule(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        -- getbufvar rather than vim.bo, which reads a hidden buffer's option by switching
        -- into the autocmd window (~10us per read, against ~0.2us)
        if
          vim.api.nvim_buf_is_loaded(bufnr)
          and vim.fn.getbufvar(bufnr, '&buftype') == ''
          and vim.fn.getbufvar(bufnr, '&modified') == 0
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

-- Equalize splits on resize. Background tabpages refit only once entered, so they wait for
-- TabEnter: visiting them here would fire Win/BufEnter and retarget focus trackers (lazygit's)
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

aucmd('BufReadPost', {
  group = augroup('last-location'),
  callback = function(event)
    local buf = event.buf

    -- BufReadPost runs before filetype detection (this autocmd is registered
    -- ahead of filetypedetect), so vim.bo.filetype is still empty here
    local ft = vim.bo[buf].filetype
    if ft == '' then
      ft = vim.filetype.match({ buf = buf }) or ''
    end

    if ft == 'gitcommit' or vim.b[buf].restored_last_position then
      return
    end

    vim.b[buf].restored_last_position = true

    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

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

-- Open help vertically to the right
aucmd('FileType', {
  group = augroup('help-right'),
  pattern = { 'help' },
  command = 'wincmd L',
})

-- Don't continue comments onto new lines
aucmd('FileType', {
  group = augroup('stop-auto-comment'),
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

local markdown_group = augroup('markdown-defaults')
-- Headings as matched by the runtime ftplugin's section jumps
local markdown_heading = [[\%(^#\{1,5\}\s\+\S\|^\S.*\n^[=-]\+$\)]]

aucmd('FileType', {
  group = markdown_group,
  pattern = { 'markdown' },
  callback = function(event)
    -- The runtime ftplugin's visual-mode section jumps, whose own maps are disabled
    -- (see g.no_markdown_maps in config/options.lua)
    local map = common.buf_mapper(event.buf)
    map(
      'x',
      ']]',
      string.format("<cmd>call search('%s', 'sW')<cr>", markdown_heading),
      'Jump to Next Section'
    )
    map(
      'x',
      '[[',
      string.format("<cmd>call search('%s', 'bsW')<cr>", markdown_heading),
      'Jump to Previous Section'
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

    -- A buffer loaded while hidden (an LSP bufload()) gets FileType and a first BufWinEnter in the
    -- autocmd window, and FileType won't fire again, so wait for a real window's BufWinEnter
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

-- Switch back to the cmdline with the key that opened the cmdline window ('cedit')
aucmd('CmdwinEnter', {
  group = augroup('cmdwin-keymaps'),
  callback = function(event)
    local map = common.buf_mapper(event.buf)
    map({ 'i', 'x', 'n', 's' }, '<C-f>', '<C-c>', 'Exit Command-Line Window Mode')
    map('n', 'q', '<cmd>q!<cr>', 'Quit Command-Line Window')
  end,
})

-- Color the cursor line number by mode, with the per-mode groups from core/catppuccin-nvim.lua;
-- ColorScheme relinks after the colorscheme resets CursorLineNr
aucmd({ 'ModeChanged', 'ColorScheme' }, {
  group = augroup('mode-line-number'),
  callback = function()
    local hl_name = UI.mode.name() .. 'Mode'
    -- Relinking redraws every window, so only relink on a target change
    if vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).link ~= hl_name then
      vim.api.nvim_set_hl(0, 'CursorLineNr', { link = hl_name })
    end
  end,
})

aucmd('InsertEnter', {
  group = augroup('clear-hlsearch-on-insert'),
  callback = function()
    if vim.v.hlsearch == 1 then
      vim.schedule(UI.color.nohlsearch)
    end
  end,
})
