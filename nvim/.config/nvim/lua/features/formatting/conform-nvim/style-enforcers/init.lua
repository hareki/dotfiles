local engine = require('features.formatting.conform-nvim.style-enforcers.engine')
local eslint = require('features.formatting.conform-nvim.style-enforcers.eslint')
local oxfmt = require('features.formatting.conform-nvim.style-enforcers.oxfmt')
local oxlint = require('features.formatting.conform-nvim.style-enforcers.oxlint')
local notifier = require('utils.notifier')

local notify = notifier.scoped('Style Enforcer')

-- In run order: oxfmt formats before the lint-fix steps, so oxlint's fixAll sees formatted
-- content. Each step runs where its server is attached (lsp/oxfmt.lua narrows oxfmt's filetypes)
--- @type features.formatting.conform-nvim.style-enforcers.engine.Entry[]
local enforcers = {
  { name = 'oxfmt', runner = oxfmt.run },
  { name = 'eslint', runner = eslint.run },
  { name = 'oxlint', runner = oxlint.run },
}

--- @class features.formatting.conform-nvim.style-enforcers
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

--- Run format and lint sequentially on a buffer with progress, under a per-buffer lock and timeout
--- @param opts? { debug?: boolean, buf?: integer, save?: boolean, on_done?: fun(ok: boolean) }
--- @return nil
function M.run(opts)
  opts = opts or {}
  local debug = opts.debug
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  local save = opts.save ~= false
  local on_done = opts.on_done

  if running_bufs[buf] then
    notify.warn('Formatting already in progress')
    return
  end

  local conform = require('conform')
  local progress_utils = require('utils.progress')

  local progress = progress_utils.create({
    pending_ms = 500,
    client_name = 'stenfo',
    -- run_all targets background buffers, so sample the client from the target
    bufnr = buf,
  })

  running_bufs[buf] = true

  local settled = false
  local timeout_timer

  -- Runs once, so a callback after the timeout can't double-report or clobber a newer run's lock
  --- @param ok boolean
  local function cleanup(ok)
    if settled then
      return
    end
    settled = true

    local snacks_util = require('snacks.util')
    snacks_util.stop(timeout_timer)
    progress:finish()
    running_bufs[buf] = nil
    if on_done then
      on_done(ok)
    end
  end

  timeout_timer = vim.defer_fn(function()
    if settled then
      return
    end
    notify.warn('Formatting/linting timed out')
    cleanup(false)
  end, TIMEOUT_MS)

  -- Under pcall: an unwritable buffer (E32, E45, E212) would throw and leak the buffer lock
  local function write()
    if not save or not vim.api.nvim_buf_is_valid(buf) then
      return true
    end

    local ok, err = pcall(vim.api.nvim_buf_call, buf, vim.cmd.update)
    if not ok then
      notify.error('Write failed: ' .. tostring(err))
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
        enforcers = enforcers,
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
              notify.warn(
                string.format('Buffer changed while `%s` was running, skipped', linter_name)
              )
            else
              local msg = debug and string.format('Linter %s error: %s', linter_name, lint_error)
                or string.format('Linter used: %s', linter_name)

              notify.warn(msg, {
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
      notify.error('Linter setup failed: ' .. tostring(err))
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

      notify.error(msg, {
        title = 'Formatting Failed',
      })
      write()
      cleanup(false)
      return
    end

    run_linters(true)
  end)
end

--- Run format+lint on all modified listed buffers, then notify a summary of counts and paths
--- @param debug boolean | nil Enable verbose error messages
--- @return nil
function M.run_all(debug)
  local modified = vim.fn.getbufinfo({ buflisted = 1, bufmodified = 1 })

  if #modified == 0 then
    notify.warn('No buffers to format')
    return
  end

  local to_run = vim.tbl_filter(function(info)
    return not running_bufs[info.bufnr]
  end, modified)

  if #to_run == 0 then
    notify.warn('All buffers are already being formatted')
    return
  end

  -- Track successes and failures by path (relative to cwd)
  local success_paths = {}
  local error_paths = {}

  local function show_results()
    local mini_icons = require('mini.icons')

    -- Build message as tuple list: { {text, hl}, {text, hl}, ... }
    local chunks = {}
    local has_error = #error_paths > 0

    --- @param header string
    --- @param header_hl string
    --- @param paths string[]
    local function add_section(header, header_hl, paths)
      table.insert(chunks, { header, header_hl })
      for _, path in ipairs(paths) do
        local icon, icon_hl = mini_icons.get('file', path)
        local dir, file = path:match('^(.-)([^/]*)$')

        table.insert(chunks, { '\n  ' .. icon .. ' ', icon_hl })
        if dir ~= '' then
          table.insert(chunks, { dir, 'SnacksPickerDir' })
        end
        table.insert(chunks, { file, 'SnacksPickerFile' })
      end
    end

    -- Happy / mixed case: successes first
    if #success_paths > 0 then
      add_section('Success:', 'DiagnosticSignOk', success_paths)
    end

    -- Failures, which also turn the summary into a warning
    if has_error then
      if #success_paths > 0 then
        table.insert(chunks, { '\n\n', 'Normal' }) -- blank line between sections
      end

      add_section('Error:', 'Error', error_paths)
      notify.warn(chunks)
    else
      notify.info(chunks)
    end
  end

  -- Preset the counter: synchronous completions could hit zero mid-loop and fire a partial summary
  local pending_count = #to_run

  for _, info in ipairs(to_run) do
    local display_path = info.name == '' and '[No Name]' or vim.fn.fnamemodify(info.name, ':.')

    M.run({
      debug = debug,
      buf = info.bufnr,
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
