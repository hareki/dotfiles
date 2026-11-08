local keymap = require('utils.keymap')

--- @module 'colorizer'
local colorizer = Defer.on_exported_call('colorizer')

--- @class features.git.git-conflict-nvim.utils
local M = {}

--- @class features.git.git-conflict-nvim.utils.State
--- @field autocmds table<integer, integer> The cursor autocmd of each buffer set up by GitConflictDetected

--- @type features.git.git-conflict-nvim.utils.State
local state = {
  autocmds = {},
}

-- The plugin's own namespace, whose region extmarks are the buffer's parsed conflicts
local conflict_ns = vim.api.nvim_create_namespace('git-conflict')

-- Window-local 'winhighlight' remaps only these groups; nvim_win_set_hl_ns would break other
-- plugins' winhighlight redirects (nvim-tree's own groups), rendering them with defaults
local conflict_winhl = table.concat({
  'DocumentHighlight:GitConflictDocumentHighlight',
  'GitSignsCurrentLineBlame:GitConflictBlame',
}, ',')

local keymaps = {
  { lhs = '<leader>co', rhs = '<Plug>(git-conflict-ours)', desc = 'Choose Ours' },
  { lhs = '<leader>ct', rhs = '<Plug>(git-conflict-theirs)', desc = 'Choose Theirs' },
  { lhs = '<leader>cb', rhs = '<Plug>(git-conflict-both)', desc = 'Choose Both' },
  { lhs = '<leader>cn', rhs = '<Plug>(git-conflict-none)', desc = 'Choose None' },
  { lhs = '[x', rhs = '<Plug>(git-conflict-prev-conflict)', desc = 'Previous Conflict' },
  { lhs = ']x', rhs = '<Plug>(git-conflict-next-conflict)', desc = 'Next Conflict' },
}

-- Tells the maps above apart from another plugin's map on the same keys
local keymap_rhs = {}
for _, map in ipairs(keymaps) do
  keymap_rhs[map.rhs] = true
end

--- @return boolean in_conflict
local function cursor_in_conflict()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  -- From column 1: a region ends at column 0 of the line after it, which would match from column 0
  local marks = vim.api.nvim_buf_get_extmarks(
    0,
    conflict_ns,
    { line, 1 },
    { line, -1 },
    { overlap = true, limit = 1 }
  )

  return marks[1] ~= nil
end

local function cleanup_buf(bufnr)
  local autocmd_id = state.autocmds[bufnr]
  if not autocmd_id then
    return
  end
  pcall(vim.api.nvim_del_autocmd, autocmd_id)

  state.autocmds[bufnr] = nil
end

--- @param win integer
--- @param in_conflict boolean
local function apply_window_winhl(win, in_conflict)
  -- Setting 'winhighlight', even to its current value, redraws the whole window on every move here
  local winhl = in_conflict and conflict_winhl or ''
  if vim.wo[win].winhighlight ~= winhl then
    vim.wo[win].winhighlight = winhl
  end
end

--- Register the autocmds that give conflicted buffers their keymaps and conflict window
--- highlights, pause colorizer and diagnostics in them, and undo it all once resolved
--- @return nil
function M.setup()
  local group =
    vim.api.nvim_create_augroup('features.git.git-conflict-nvim.keymaps', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitConflictDetected',
    callback = function(event)
      local bufnr = event.data.buf

      -- Detected fires on every parse, and this state is set last, so the rest is already in place
      if state.autocmds[bufnr] then
        return
      end

      local map = keymap.buf_mapper(bufnr, { prefix = 'Git Conflict: ' })
      for _, entry in ipairs(keymaps) do
        map('n', entry.lhs, entry.rhs, entry.desc)
      end

      vim.b[bufnr].git_conflict = true

      -- Colorizer serves a filetype list, so this buffer may not be attached: tell Resolved
      vim.b[bufnr].git_conflict_colorized = package.loaded['colorizer'] ~= nil
        and colorizer.detach_from_buffer(bufnr) ~= -1
      vim.diagnostic.enable(false, { bufnr = bufnr })

      state.autocmds[bufnr] = vim.api.nvim_create_autocmd(
        { 'CursorMoved', 'CursorMovedI', 'BufEnter', 'BufLeave' },
        {
          group = group,
          buf = bufnr,
          callback = function(args)
            -- 'winhighlight' outlives a buffer swap in its window (nvim-tree, pickers), so clear it
            -- on BufLeave; BufEnter restores it in a refocused window that clear also hit
            local in_conflict = args.event ~= 'BufLeave' and cursor_in_conflict()
            apply_window_winhl(vim.api.nvim_get_current_win(), in_conflict)
          end,
        }
      )

      -- The plugin parses, and fires this, inside a decoration provider's on_win, where changing
      -- an option is unsafe; a buffer left by then gets its highlights from BufEnter on return
      vim.schedule(function()
        if state.autocmds[bufnr] and vim.api.nvim_get_current_buf() == bufnr then
          apply_window_winhl(vim.api.nvim_get_current_win(), cursor_in_conflict())
        end
      end)
    end,
  })

  -- Clean up deleted buffers' state; wiping an unlisted buffer never fires BufDelete
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = group,
    callback = function(event)
      -- :bdelete clears the git_conflict flag gating Resolved's cleanup but not the disabled
      -- diagnostics, so re-enable them (Detected disables them again if still conflicted)
      if state.autocmds[event.buf] then
        vim.diagnostic.enable(true, { bufnr = event.buf })
      end
      cleanup_buf(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitConflictResolved',
    callback = function(event)
      local bufnr = event.data.buf
      cleanup_buf(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      -- Delete only Detected's maps, whatever the flag says: codediff's merge view claims
      -- the same keys on this buffer and hands Detected's maps back once it lets go
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, 'n')) do
        if keymap_rhs[map.rhs] then
          vim.api.nvim_buf_del_keymap(bufnr, 'n', map.lhs)
        end
      end

      -- Resolved fires on every parse (its mappings flag stays unset): undo only what Detected did
      if not vim.b[bufnr].git_conflict then
        return
      end
      vim.b[bufnr].git_conflict = nil

      if vim.b[bufnr].git_conflict_colorized then
        colorizer.attach_to_buffer(bufnr)
      end
      vim.diagnostic.enable(true, { bufnr = bufnr })

      for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
        apply_window_winhl(win, false)
      end
    end,
  })
end

--- Whether the buffer currently holds conflict markers
--- @param bufnr integer
--- @return boolean
function M.is_conflicted(bufnr)
  return vim.b[bufnr].git_conflict == true
end

return M
