local package_utils = require('utils.package')

--- @module 'colorizer'
local colorizer = Defer.on_exported_call('colorizer')

--- @class features.git.git-conflict.utils
local M = {}

--- @class features.git.git-conflict.utils.BufState
--- @field autocmd_id integer
--- @field timer uv.uv_timer_t?

--- @class features.git.git-conflict.utils.State
--- @field bufs table<integer, features.git.git-conflict.utils.BufState> Buffers set up by GitConflictDetected

--- @type features.git.git-conflict.utils.State
M.state = {
  bufs = {},
}

-- Maximum number of lines to search backward/forward for conflict markers
local CONFLICT_SEARCH_RANGE = 500

-- Debounce window for the cursor-in-conflict scan. The scan walks up to
-- 1000 lines, which can lag when cursor movement is held down.
local CURSOR_DEBOUNCE_MS = 100

-- Window-local 'winhighlight' remaps only these groups; nvim_win_set_hl_ns would break other
-- plugins' winhighlight redirects (nvim-tree's picker StatusLine), rendering them with defaults
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
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1 -- Convert to 0-based
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Bulk-fetch the entire search window in a single API call (vs per-line fetches)
  local fetch_start = math.max(0, line - CONFLICT_SEARCH_RANGE)
  local fetch_end = math.min(line_count, line + CONFLICT_SEARCH_RANGE + 1)
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, fetch_start, fetch_end, false)

  --- Get line text by absolute 0-based line number from the bulk-fetched range
  --- @param abs_idx integer
  --- @return string line_text The line content, or empty string if out of range
  local function get_line(abs_idx)
    return all_lines[abs_idx - fetch_start + 1] or ''
  end

  local start_line = nil

  for i = line, fetch_start, -1 do
    local line_text = get_line(i)
    if line_text:match('^<<<<<<<') then
      start_line = i
      break
    end

    -- Early exit if we hit another conflict end marker (but not the current line)
    if i ~= line and line_text:match('^>>>>>>>') then
      return false
    end
  end

  if not start_line then
    return false
  end

  local middle_line = nil
  local end_line = nil
  local max_search = math.min(line_count - 1, start_line + CONFLICT_SEARCH_RANGE)

  for i = start_line + 1, max_search do
    local line_text = get_line(i)

    if not middle_line and line_text:match('^=======') then
      middle_line = i
    elseif line_text:match('^>>>>>>>') then
      end_line = i
      break
    end
  end

  return middle_line ~= nil and end_line ~= nil and line <= end_line
end

local function cleanup_buf(bufnr)
  local state = M.state.bufs[bufnr]
  if not state then
    return
  end
  pcall(vim.api.nvim_del_autocmd, state.autocmd_id)

  Snacks.util.stop(state.timer)
  M.state.bufs[bufnr] = nil
end

--- @param win integer
--- @param in_conflict boolean
local function apply_window_winhl(win, in_conflict)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  -- Setting 'winhighlight', even to its current value, redraws the whole window, and the
  -- debounced cursor check lands here on every pause in a conflicted buffer
  local winhl = in_conflict and conflict_winhl or ''
  if vim.wo[win].winhighlight ~= winhl then
    vim.wo[win].winhighlight = winhl
  end
end

local function schedule_cursor_check(bufnr)
  local state = M.state.bufs[bufnr]
  if not state then
    return
  end

  if not state.timer then
    state.timer = vim.uv.new_timer()
  end

  state.timer:stop()
  state.timer:start(
    CURSOR_DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      -- Skip if user moved to a different buffer in the meantime; BufLeave
      -- already cleared winhl, and BufWinEnter will re-apply on return.
      if vim.api.nvim_get_current_buf() ~= bufnr then
        return
      end
      if not M.state.bufs[bufnr] then
        return
      end
      apply_window_winhl(vim.api.nvim_get_current_win(), cursor_in_conflict())
    end)
  )
end

--- Register the autocmds that give conflicted buffers their keymaps and conflict window
--- highlights, pause colorizer and diagnostics in them, and undo it all once resolved
--- @return nil
function M.setup()
  local group = vim.api.nvim_create_augroup('features.git.git-conflict.keymaps', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'GitConflictDetected',
    callback = function(event)
      local bufnr = event.data.buf

      -- Detected fires on every parse of a conflicted buffer, and its state is only
      -- set up below, after the keymaps and flag, so everything is already in place
      if M.state.bufs[bufnr] then
        return
      end

      for _, map in ipairs(keymaps) do
        vim.keymap.set('n', map.lhs, map.rhs, {
          desc = 'Git Conflict: ' .. map.desc,
          buffer = bufnr,
        })
      end

      vim.b[bufnr].git_conflict = true

      if package_utils.is_loaded('nvim-colorizer.lua') then
        colorizer.detach_from_buffer(bufnr)
      end
      vim.diagnostic.enable(false, { bufnr = bufnr })

      local autocmd_id = vim.api.nvim_create_autocmd(
        { 'CursorMoved', 'CursorMovedI', 'BufWinEnter', 'BufEnter', 'BufLeave' },
        {
          group = group,
          buffer = bufnr,
          callback = function(args)
            local state = M.state.bufs[bufnr]
            if not state then
              return
            end

            -- 'winhighlight' outlives a buffer swap in its window (nvim-tree, pickers), so clear it
            -- when the conflict buffer leaves; BufWinEnter/BufEnter/CursorMoved re-apply it
            if args.event == 'BufLeave' then
              if state.timer then
                state.timer:stop()
              end
              apply_window_winhl(vim.api.nvim_get_current_win(), false)
              return
            end

            -- Cursor moves are debounced; entering stays synchronous so a new split shows no gap,
            -- and BufEnter covers a refocused window whose winhl BufLeave cleared
            if args.event == 'CursorMoved' or args.event == 'CursorMovedI' then
              schedule_cursor_check(bufnr)
              return
            end

            apply_window_winhl(vim.api.nvim_get_current_win(), cursor_in_conflict())
          end,
        }
      )

      M.state.bufs[bufnr] = {
        autocmd_id = autocmd_id,
      }

      -- Wait a bit for the position to be stable and then initialize the highlights
      schedule_cursor_check(bufnr)
    end,
  })

  -- Clean up state when buffers are deleted to prevent memory leak
  -- (BufWipeout included: wiping an unlisted buffer never fires BufDelete)
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = group,
    callback = function(event)
      -- :bdelete clears the git_conflict flag gating Resolved's cleanup but not the disabled
      -- diagnostics, so re-enable them (Detected disables them again if still conflicted)
      if M.state.bufs[event.buf] then
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

      -- Resolved fires on every parse (with default_mappings = false the
      -- fork's mappings flag is never set), so only undo what Detected did
      if not vim.b[bufnr].git_conflict then
        return
      end
      vim.b[bufnr].git_conflict = nil

      if package_utils.is_loaded('nvim-colorizer.lua') then
        colorizer.attach_to_buffer(bufnr)
      end
      vim.diagnostic.enable(true, { bufnr = bufnr })

      for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
        vim.wo[win].winhighlight = ''
      end
    end,
  })
end

return M
