local conform = require('features.formatting.conform-nvim.style-enforcer.conform-nvim')
local eslint = require('features.formatting.conform-nvim.style-enforcer.eslint')
local notifier = require('utils.notifier')
local oxfmt = require('features.formatting.conform-nvim.style-enforcer.oxfmt')
local oxlint = require('features.formatting.conform-nvim.style-enforcer.oxlint')

local notify = notifier.scoped('Style Enforcer')

--- One step of the save pipeline, an adapter over one tool
--- @class features.formatting.conform-nvim.style-enforcer.Step
--- @field name string The tool, named in notices
--- @field label string Progress title while the step runs
--- @field applies? fun(buf: integer): boolean The gate; without it, the step runs where `client` is attached
--- @field client? string The LSP client the step drives, by name; its run gets an LspContext
--- @field kind 'format' | 'fix' What the step does to the buffer, which sets its failure notice's level and title
--- @field run fun(ctx: features.formatting.conform-nvim.style-enforcer.Context)
--- @field failure? fun(err: string, debug?: boolean, buf: integer): string The failure notice's text; default: it names the tool

--- What a step's run gets; `done` does nothing once the run has ended
--- @class features.formatting.conform-nvim.style-enforcer.Context
--- @field buf integer
--- @field done fun(err?: string) Report the step's end: the next step starts, or err ends the run

--- The context of a step that names a client: `request` fails the step on a server error or an edit
--- in flight, and `execute`'s workspace/executeCommand reply ends it; both pass `done`'s guard
--- @class features.formatting.conform-nvim.style-enforcer.LspContext: features.formatting.conform-nvim.style-enforcer.Context
--- @field client vim.lsp.Client Looked up as the step starts
--- @field request fun(method: vim.lsp.protocol.Method.ClientToServer.Request, params: table, on_result: fun(result: any))
--- @field execute fun(command: string, argument: table)

--- @class features.formatting.conform-nvim.style-enforcer.RunOpts
--- @field debug? boolean Failure notices carry the tool's error
--- @field buf? integer Default: the current buffer
--- @field save? boolean Write the buffer at the end (default true)
--- @field on_done? fun(ok: boolean) Called once, when the run ends
--- @field steps? features.formatting.conform-nvim.style-enforcer.Step[] For tests, in place of STEPS
--- @field timeout_ms? integer For tests, in place of TIMEOUT_MS

-- In run order: formatting first, so oxlint's fixAll sees formatted content; an LSP step runs
-- where its server is attached (lsp/oxfmt.lua narrows oxfmt's filetypes)
--- @type features.formatting.conform-nvim.style-enforcer.Step[]
local STEPS = { conform, oxfmt, eslint, oxlint }

-- Timeout to prevent permanent locks
local TIMEOUT_MS = 5000

-- The error a request reports when the buffer was edited while it was in flight
local BUFFER_CHANGED = 'buffer changed while running'

-- A failed step's notice by the step's kind; `tool` words the default text
local KIND_FAILURES = {
  format = { level = 'error', title = 'Formatting Failed', tool = 'Formatter' },
  fix = { level = 'warn', title = 'Fixing Failed', tool = 'Linter' },
}

--- @class features.formatting.conform-nvim.style-enforcer
local M = {}

local running_bufs = {}

--- @param step features.formatting.conform-nvim.style-enforcer.Step
--- @param buf integer
--- @return boolean
local function applies(step, buf)
  if step.applies then
    return step.applies(buf)
  end

  return #vim.lsp.get_clients({ name = step.client, bufnr = buf }) > 0
end

--- @param buf integer
--- @return boolean ok
local function write(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return true
  end

  -- Under pcall: an unwritable buffer (E32, E45, E212) would throw and leak the buffer lock
  local ok, err = pcall(vim.api.nvim_buf_call, buf, vim.cmd.update)
  if not ok then
    notify.error('Write failed: ' .. tostring(err))
  end

  return ok
end

--- @param step features.formatting.conform-nvim.style-enforcer.Step
--- @param err string
--- @param debug? boolean
--- @param buf integer
local function notify_failure(step, err, debug, buf)
  if err == BUFFER_CHANGED then
    notify.warn(string.format('Buffer changed while `%s` was running, skipped', step.name))
    return
  end

  local kind = KIND_FAILURES[step.kind]
  local msg = step.failure and step.failure(err, debug, buf)
    or debug and string.format('%s %s error: %s', kind.tool, step.name, err)
    or string.format('%s used: %s', kind.tool, step.name)
  notify[kind.level](msg, { title = kind.title })
end

--- @param buf integer
--- @param client vim.lsp.Client
--- @param live fun(fn: function): function
--- @param done fun(err?: string)
--- @return features.formatting.conform-nvim.style-enforcer.LspContext
local function lsp_context(buf, client, live, done)
  return {
    buf = buf,
    client = client,
    done = done,

    request = function(method, params, on_result)
      -- changedtick rather than the reply's ctx.version, which an autoread reload leaves unchanged
      local changedtick = vim.api.nvim_buf_get_changedtick(buf)

      client:request(
        method,
        params,
        live(function(err, result)
          if err then
            return done(err.message)
          end

          -- Edits from the reply's unversioned positions would corrupt the text
          if
            not vim.api.nvim_buf_is_valid(buf)
            or vim.api.nvim_buf_get_changedtick(buf) ~= changedtick
          then
            return done(BUFFER_CHANGED)
          end

          on_result(result)
        end),
        buf
      )
    end,

    execute = function(command, argument)
      local params = { command = command, arguments = { argument } }
      client:request(
        'workspace/executeCommand',
        params,
        live(function(err)
          done(err and err.message)
        end),
        buf
      )
    end,
  }
end

--- Run a buffer's steps in order and write it, under a per-buffer lock and timeout, with progress
--- @param opts? features.formatting.conform-nvim.style-enforcer.RunOpts
--- @return nil
function M.run(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  if running_bufs[buf] then
    notify.warn('Formatting already in progress')
    return
  end

  local steps = vim.tbl_filter(function(step)
    return applies(step, buf)
  end, opts.steps or STEPS)

  local progress_utils = require('utils.progress')
  local snacks_util = require('snacks.util')

  local progress = progress_utils.create({
    pending_ms = 500,
    client_name = 'stenfo',
    -- run_all targets background buffers, so sample the client from the target
    bufnr = buf,
  })

  running_bufs[buf] = true

  local ended = false
  local timeout_timer
  -- The step in flight, which the timeout names
  --- @type features.formatting.conform-nvim.style-enforcer.Step
  local current

  -- Every step callback and the timeout pass through here: after the run ends, none can start a
  -- step, edit the buffer, double-report or clobber a newer run's lock (applyEdit escapes it)
  --- @param fn function
  --- @return function
  local function live(fn)
    return function(...)
      if not ended then
        return fn(...)
      end
    end
  end

  --- @param ok boolean
  --- @param should_write boolean
  local function finish(ok, should_write)
    ended = true
    snacks_util.stop(timeout_timer)

    if should_write and opts.save ~= false then
      ok = write(buf) and ok
    end

    progress:finish()
    running_bufs[buf] = nil
    if opts.on_done then
      opts.on_done(ok)
    end
  end

  -- A failed step ends the run: after BUFFER_CHANGED, whoever is editing the buffer would race
  -- the remaining steps. What the steps before it did is still written
  --- @param step features.formatting.conform-nvim.style-enforcer.Step
  --- @param err string
  local function fail(step, err)
    notify_failure(step, err, opts.debug, buf)
    finish(false, true)
  end

  --- @param idx integer
  local function start(idx)
    -- A step's reply can outlive its buffer
    if not vim.api.nvim_buf_is_valid(buf) then
      return finish(false, false)
    end

    local step = steps[idx]
    if not step then
      return finish(true, true)
    end
    current = step

    -- A failed step ends the run, so every one before idx has finished
    if idx == 1 then
      progress:start(step.label)
    else
      progress:report(step.label, 100 * (idx - 1) / #steps)
    end

    local done = live(function(err)
      if err then
        fail(step, err)
      else
        start(idx + 1)
      end
    end)

    --- @type features.formatting.conform-nvim.style-enforcer.Context
    local ctx = { buf = buf, done = done }
    if step.client then
      -- Looked up again rather than kept from the gate: it may have detached meanwhile
      local client = vim.lsp.get_clients({ name = step.client, bufnr = buf })[1]
      if not client then
        return fail(step, step.client .. ' client missing')
      end

      ctx = lsp_context(buf, client, live, done)
    end

    -- A step that throws fails like a reported error instead of holding the lock until the timeout
    local ok, err = pcall(step.run, ctx)
    if not ok then
      done(tostring(err))
    end
  end

  timeout_timer = vim.defer_fn(
    live(function()
      notify.warn(string.format('%s timed out', current.label))
      finish(false, false)
    end),
    opts.timeout_ms or TIMEOUT_MS
  )

  start(1)
end

--- Run the pipeline on all modified listed buffers, then notify a summary of counts and paths
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
