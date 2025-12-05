local M = {}

local running_bufs = {}
-- Timeout to prevent permanent locks (10 seconds)
local TIMEOUT_MS = 10000

local function get_formatter_names(buf)
  local list, uses_lsp = require('conform').list_formatters_to_run(buf)

  local names = {}
  for _, f in ipairs(list or {}) do
    if f and f.name then
      names[#names + 1] = f.name
    end
  end
  if uses_lsp then
    names[#names + 1] = 'lsp'
  end

  return #names > 0 and table.concat(names, ', ') or 'No formatter found'
end

---@param opts? { debug?: boolean, buf?: integer, save?: boolean, on_done?: fun(ok: boolean, err?: string) }
function M.run(opts)
  opts = opts or {}
  local debug = opts.debug
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local save = opts.save ~= false
  local on_done = opts.on_done

  local function finish(ok, err)
    if on_done then
      on_done(ok, err)
    end
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    finish(false, 'Invalid buffer')
    return
  end

  -- Prevent concurrent format+lint operations on the same buffer
  if running_bufs[buf] then
    notifier.warn('Formatting already in progress', { title = 'Style Enforcer' })
    finish(false, 'Already in progress')
    return
  end

  running_bufs[buf] = true

  -- Set timeout to auto-cleanup if something goes wrong
  local timeout_timer = vim.fn.timer_start(TIMEOUT_MS, function()
    if running_bufs[buf] then
      running_bufs[buf] = nil
      notifier.warn('Formatting/linting timed out', { title = 'Style Enforcer' })
      finish(false, 'Timed out')
    end
  end)

  local function cleanup(ok, err)
    -- Cancel timeout timer and clean up lock
    pcall(vim.fn.timer_stop, timeout_timer)
    running_bufs[buf] = nil
    finish(ok, err)
  end

  local conform = require('conform')
  local linters = require('utils.linters')

  local progress = require('utils.progress').create({
    pending_ms = 0,
    client_name = 'stenfo',
  })

  local function write()
    if not save then
      return
    end

    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    if vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd.write()
      end)
    end
  end

  local function run_linters(formatted)
    if not vim.api.nvim_buf_is_valid(buf) then
      cleanup(false, 'Buffer became invalid')
      return
    end

    local total = #linters.names_for_filetype(vim.bo[buf].filetype) + (formatted and 1 or 0)
    local done_count = formatted and 1 or 0
    local percentage = 100 / total
    local had_lint_error = false

    local ok, err = pcall(function()
      linters.run_by_ft({
        bufnr = buf,
        on_start = function(linter_name)
          local label = 'Linting (' .. linter_name .. ')'
          if done_count == 0 then
            progress:start(label)
          else
            progress:report(label, percentage * done_count)
          end
        end,
        on_done = function(linter_name, linter_ok, lint_error)
          if not linter_ok and lint_error then
            had_lint_error = true
            local msg = debug and ('Linter %s error: %s'):format(linter_name, lint_error)
              or ('Linter used: %s'):format(linter_name)

            notifier.warn(msg, {
              title = 'Linting Failed',
            })
          end

          done_count = done_count + (linter_name == 'none' and 0 or 1)
          if done_count == total then
            write()
            progress:finish()
            cleanup(not had_lint_error)
          end
        end,
      })
    end)

    -- If linter setup fails, ensure cleanup
    if not ok then
      notifier.error('Linter setup failed: ' .. tostring(err), { title = 'Style Enforcer' })
      write()
      progress:finish()
      cleanup(false, err)
    end
  end

  -- Recheck buffer validity before formatting (could have been deleted during setup)
  if not vim.api.nvim_buf_is_valid(buf) then
    cleanup(false, 'Buffer became invalid')
    return
  end

  local formatters, uses_lsp = require('conform').list_formatters_to_run(buf)
  local should_format = (formatters and #formatters > 0) or uses_lsp

  if not should_format then
    run_linters(false)
    return
  end

  progress:start('Formatting')
  conform.format({
    async = true,
    bufnr = buf,
    quiet = true,
  }, function(format_error)
    if format_error then
      local msg = debug and 'Format error: ' .. format_error
        or ('Formatter(s) used: `%s` \nSee `:ConformInfo` for more information'):format(
          get_formatter_names(buf)
        )

      notifier.error(msg, {
        title = 'Formatting Failed',
      })
      write()
      progress:finish()
      cleanup(false, format_error)
      return
    end

    run_linters(true)
  end)
end

---Run format+lint on all buffers from scope.nvim
---@param debug boolean|nil
function M.run_all(debug)
  local scope_core = require('scope.core')

  scope_core.revalidate()

  local all_scope_buffers = {}
  for _, bufs in pairs(scope_core.cache) do
    for _, buf in pairs(bufs) do
      if vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1 and vim.bo[buf].modified then
        table.insert(all_scope_buffers, buf)
      end
    end
  end

  if #all_scope_buffers == 0 then
    notifier.warn('No buffers to format', { title = 'Style Enforcer' })
    return
  end

  -- Track successes and failures by path (relative to cwd)
  local success_paths = {}
  local error_paths = {}
  local pending_count = 0
  local skipped_count = 0

  -- Helper to get a nice display path
  local function buf_display_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      return '[No Name]'
    end
    -- relative to current working directory
    return vim.fn.fnamemodify(name, ':.')
  end

  local function show_results()
    -- If nothing was actually started (everything was already running), do nothing
    if #success_paths == 0 and #error_paths == 0 then
      return
    end

    local mini_icons = require('mini.icons')

    -- Helper to get icon and its highlight group for a file path
    local function get_icon_with_hl(path)
      local icon, hl, _ = mini_icons.get('file', path)
      return icon or '', hl or 'Normal'
    end

    -- Helper to split path into directory and filename
    local function split_path(path)
      local dir, file = path:match('^(.*/)(.*)')
      if not dir then
        return '', path -- No directory, just filename
      end
      return dir, file
    end

    -- Build message as tuple list: { {text, hl}, {text, hl}, ... }
    local chunks = {}
    local has_error = #error_paths > 0

    -- Happy / mixed case: successes first
    if #success_paths > 0 then
      table.insert(chunks, { 'Success:\n', 'DiagnosticSignOk' })
      for index, path in ipairs(success_paths) do
        local icon, icon_hl = get_icon_with_hl(path)
        local dir, file = split_path(path)
        local is_last = index == #success_paths and not has_error

        table.insert(chunks, { '  ' .. icon .. ' ', icon_hl })
        if dir ~= '' then
          table.insert(chunks, { dir, 'SnacksPickerDir' })
        end
        table.insert(chunks, { file .. (is_last and '' or '\n'), 'SnacksPickerFile' })
      end
    end

    -- Failures
    if #error_paths > 0 then
      if #success_paths > 0 then
        table.insert(chunks, { '\n', 'Normal' }) -- blank line between sections
      end

      table.insert(chunks, { 'Error:\n', 'Error' })
      for index, path in ipairs(error_paths) do
        local icon, icon_hl = get_icon_with_hl(path)
        local dir, file = split_path(path)
        local is_last = index == #error_paths

        table.insert(chunks, { '  ' .. icon .. ' ', icon_hl })
        if dir ~= '' then
          table.insert(chunks, { dir, 'SnacksPickerDir' })
        end
        table.insert(chunks, { file .. (is_last and '' or '\n'), 'SnacksPickerFile' })
      end
    end

    -- Choose warn/info depending on whether there were failures
    if #error_paths > 0 then
      notifier.warn(chunks, { title = 'Style Enforcer' })
    else
      notifier.info(chunks, { title = 'Style Enforcer' })
    end
  end

  for _, buf in ipairs(all_scope_buffers) do
    -- Skip if already running on this buffer
    if running_bufs[buf] then
      skipped_count = skipped_count + 1
    else
      pending_count = pending_count + 1
      local display_path = buf_display_path(buf)

      M.run({
        debug = debug,
        buf = buf,
        on_done = function(ok, _err)
          if ok then
            table.insert(success_paths, display_path)
          else
            table.insert(error_paths, display_path)
          end

          pending_count = pending_count - 1
          if pending_count == 0 then
            vim.schedule(show_results)
          end
        end,
      })
    end
  end

  -- If all buffers were skipped (already running), show nothing
  if pending_count == 0 and skipped_count > 0 then
    notifier.warn('All buffers are already being formatted', { title = 'Style Enforcer' })
  end
end

return M
