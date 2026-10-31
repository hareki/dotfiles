local engine = require('utils.style-enforcers.engine')
local eslint = require('utils.style-enforcers.eslint')
local oxfmt = require('utils.style-enforcers.oxfmt')
local oxlint = require('utils.style-enforcers.oxlint')

-- In run order: oxfmt formats before the lint-fix steps, so oxlint's fixAll sees formatted
-- content. Each step runs where its server is attached (lsp/oxfmt.lua narrows oxfmt's filetypes)
engine.register('oxfmt', oxfmt.run)
engine.register('eslint', eslint.run)
engine.register('oxlint', oxlint.run)

--- @class utils.style-enforcers
local M = {}

local running_bufs = {}
-- Timeout to prevent permanent locks
local TIMEOUT_MS = 5000

--- @param formatters conform.FormatterInfo[]
--- @param uses_lsp boolean
--- @return string names
local function formatter_names(formatters, uses_lsp)
  local names = vim.tbl_map(function(formatter)
    return formatter.name
  end, formatters)

  if uses_lsp then
    names[#names + 1] = 'lsp'
  end

  return table.concat(names, ', ')
end

--- Run format and lint sequentially on a buffer with progress tracking
--- Prevents concurrent operations on the same buffer with locks and timeout.
--- @param opts? { debug?: boolean, buf?: integer, save?: boolean, on_done?: fun(ok: boolean) }
--- @return nil
function M.run(opts)
  opts = opts or {}
  local debug = opts.debug
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local save = opts.save ~= false
  local on_done = opts.on_done

  if running_bufs[buf] then
    Notifier.warn('Formatting already in progress', { title = 'Style Enforcer' })
    return
  end

  local conform = require('conform')
  local progress_utils = require('utils.progress')

  local progress = progress_utils.create({
    pending_ms = 500,
    client_name = 'stenfo',
    -- run_all targets background buffers; sample the client from the target,
    -- not whatever buffer happens to be current
    bufnr = buf,
  })

  running_bufs[buf] = true

  local settled = false
  local timeout_timer

  -- Single completion point, ending the progress, firing on_done and releasing the lock once, so a
  -- callback landing after the timeout can't double-report or clobber a newer run's lock on the
  -- same buffer
  --- @param ok boolean
  local function cleanup(ok)
    if settled then
      return
    end
    settled = true

    Snacks.util.stop(timeout_timer)
    progress:finish()
    running_bufs[buf] = nil
    if on_done then
      on_done(ok)
    end
  end

  -- Auto-cleanup if something goes wrong
  timeout_timer = vim.defer_fn(function()
    if settled then
      return
    end
    Notifier.warn('Formatting/linting timed out', { title = 'Style Enforcer' })
    cleanup(false)
  end, TIMEOUT_MS)

  -- :update writes only unsaved changes, under pcall: an unwritable buffer (E32, E45, E212) would
  -- otherwise throw out of the async pipeline and leak the buffer lock
  local function write()
    if not save or not vim.api.nvim_buf_is_valid(buf) then
      return true
    end

    local ok, err = pcall(vim.api.nvim_buf_call, buf, vim.cmd.update)
    if not ok then
      Notifier.error('Write failed: ' .. tostring(err), { title = 'Style Enforcer' })
    end

    return ok
  end

  local function run_linters(formatted)
    if not vim.api.nvim_buf_is_valid(buf) then
      cleanup(false)
      return
    end

    -- The format step, when it ran, counts as one finished step of the progress
    local done_offset = formatted and 1 or 0

    local ok, err = pcall(function()
      engine.run_for_buf({
        bufnr = buf,
        on_start = function(linter_name, idx, total)
          if settled then
            return
          end

          local label = 'Linting (' .. linter_name .. ')'
          -- A failed enforcer ends the run, so every one before idx has finished
          local done = done_offset + idx - 1
          if done == 0 then
            progress:start(label)
          else
            progress:report(label, 100 * done / (done_offset + total))
          end
        end,
        on_done = function(linter_name, linter_ok, lint_error)
          if not linter_ok then
            if lint_error == engine.BUFFER_CHANGED then
              Notifier.warn(
                string.format('Buffer changed while `%s` was running, skipped', linter_name),
                { title = 'Style Enforcer' }
              )
            else
              local msg = debug and string.format('Linter %s error: %s', linter_name, lint_error)
                or string.format('Linter used: %s', linter_name)

              Notifier.warn(msg, {
                title = 'Linting Failed',
              })
            end
          end
        end,
        on_complete = function(all_ok)
          if settled then
            return
          end

          cleanup(write() and all_ok)
        end,
      })
    end)

    if not ok then
      Notifier.error('Linter setup failed: ' .. tostring(err), { title = 'Style Enforcer' })
      write()
      cleanup(false)
    end
  end

  local formatters, uses_lsp = conform.list_formatters_to_run(buf)
  local should_format = #formatters > 0 or uses_lsp

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
    if settled then
      return
    end

    if format_error then
      local msg = debug and 'Format error: ' .. format_error
        or string.format(
          'Formatter(s) used: `%s` \nSee `:ConformInfo` for more information',
          formatter_names(formatters, uses_lsp)
        )

      Notifier.error(msg, {
        title = 'Formatting Failed',
      })
      write()
      cleanup(false)
      return
    end

    run_linters(true)
  end)
end

--- Run format+lint on all modified listed buffers
--- Shows a summary notification with success/error counts and file paths.
--- @param debug boolean | nil Enable verbose error messages
--- @return nil
function M.run_all(debug)
  local all_buffers = vim.tbl_map(function(info)
    return info.bufnr
  end, vim.fn.getbufinfo({ buflisted = 1, bufmodified = 1 }))

  if #all_buffers == 0 then
    Notifier.warn('No buffers to format', { title = 'Style Enforcer' })
    return
  end

  local to_run = vim.tbl_filter(function(buf)
    return not running_bufs[buf]
  end, all_buffers)

  if #to_run == 0 then
    Notifier.warn('All buffers are already being formatted', { title = 'Style Enforcer' })
    return
  end

  -- Track successes and failures by path (relative to cwd)
  local success_paths = {}
  local error_paths = {}

  local function buf_display_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then
      return '[No Name]'
    end
    return vim.fn.fnamemodify(name, ':.')
  end

  local function show_results()
    local mini_icons = require('mini.icons')

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

    --- @param header string
    --- @param header_hl string
    --- @param paths string[]
    --- @param ends_message boolean Whether no section follows this one
    local function add_section(header, header_hl, paths, ends_message)
      table.insert(chunks, { header, header_hl })
      for index, path in ipairs(paths) do
        local icon, icon_hl = mini_icons.get('file', path)
        local dir, file = split_path(path)
        local is_last = ends_message and index == #paths

        table.insert(chunks, { '  ' .. icon .. ' ', icon_hl })
        if dir ~= '' then
          table.insert(chunks, { dir, 'SnacksPickerDir' })
        end
        table.insert(chunks, { file .. (is_last and '' or '\n'), 'SnacksPickerFile' })
      end
    end

    -- Happy / mixed case: successes first
    if #success_paths > 0 then
      add_section('Success:\n', 'DiagnosticSignOk', success_paths, not has_error)
    end

    -- Failures, which also turn the summary into a warning
    if has_error then
      if #success_paths > 0 then
        table.insert(chunks, { '\n', 'Normal' }) -- blank line between sections
      end

      add_section('Error:\n', 'Error', error_paths, true)
      Notifier.warn(chunks, { title = 'Style Enforcer' })
    else
      Notifier.info(chunks, { title = 'Style Enforcer' })
    end
  end

  -- Preset the counter: a buffer with no formatter or linter completes synchronously in M.run, so
  -- a live-incremented counter could hit zero mid-loop and fire a premature partial summary
  local pending_count = #to_run

  for _, buf in ipairs(to_run) do
    local display_path = buf_display_path(buf)

    M.run({
      debug = debug,
      buf = buf,
      on_done = function(ok)
        if ok then
          table.insert(success_paths, display_path)
        else
          table.insert(error_paths, display_path)
        end

        pending_count = pending_count - 1
        if pending_count == 0 then
          show_results()
        end
      end,
    })
  end
end

return M
