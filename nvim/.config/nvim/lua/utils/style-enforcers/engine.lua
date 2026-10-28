--- @class utils.style-enforcers.RunOpts
--- @field bufnr integer
--- @field on_start fun(name: string, idx: integer, total: integer)
--- @field on_done fun(name: string, ok: boolean, err?: string) Called after each enforcer
--- @field on_complete fun() Called once when the run ends: after the last enforcer, or the first failed one

--- @class utils.style-enforcers.engine
local M = {}

--- Error a runner reports when the buffer was edited while its request was in flight,
--- so the result no longer applies to it
M.BUFFER_CHANGED = 'buffer changed while running'

--- @alias utils.style-enforcers.RunnerOpts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @alias utils.style-enforcers.Runner fun(opts: utils.style-enforcers.RunnerOpts)

--- @class utils.style-enforcers.Entry
--- @field name string LSP client the runner drives, doubling as the enforcer name
--- @field runner utils.style-enforcers.Runner

--- @type utils.style-enforcers.Entry[]
local entries = {}

--- Register an enforcer driven by the LSP client `name`, skipping buffers that client isn't
--- attached to; enforcers run in registration order
--- @param name string
--- @param runner utils.style-enforcers.Runner
--- @return nil
function M.register(name, runner)
  entries[#entries + 1] = { name = name, runner = runner }
end

--- Registered enforcers whose client is attached to a buffer, in registration order
--- @param bufnr integer
--- @return utils.style-enforcers.Entry[]
local function entries_for_buf(bufnr)
  return vim.tbl_filter(function(entry)
    return #vim.lsp.get_clients({ name = entry.name, bufnr = bufnr }) > 0
  end, entries)
end

--- Run the matched enforcers sequentially
--- @param matched utils.style-enforcers.Entry[]
--- @param opts utils.style-enforcers.RunOpts
--- @param idx integer
local function run_next(matched, opts, idx)
  local entry = matched[idx]
  if not entry then
    return opts.on_complete()
  end

  opts.on_start(entry.name, idx, #matched)

  --- @param ok boolean
  --- @param err? string
  local function on_done(ok, err)
    opts.on_done(entry.name, ok, err)

    -- A failed enforcer ends the run like a failed format step ends the pipeline (init.lua): after
    -- BUFFER_CHANGED, whoever is editing the buffer would race the remaining enforcers
    if ok then
      run_next(matched, opts, idx + 1)
    else
      opts.on_complete()
    end
  end

  -- Looked up again rather than kept from the match: it may have detached while the
  -- earlier enforcers ran
  local client = vim.lsp.get_clients({ name = entry.name, bufnr = opts.bufnr })[1]
  if not client then
    return on_done(false, entry.name .. ' client missing')
  end

  entry.runner({ bufnr = opts.bufnr, client = client, on_done = on_done })
end

--- Run every registered enforcer that applies to the buffer
--- @param opts utils.style-enforcers.RunOpts
--- @return nil
function M.run_for_buf(opts)
  run_next(entries_for_buf(opts.bufnr), opts, 1)
end

--- Send a workspace/executeCommand for a runner, reporting the server's error to its on_done
--- @param opts utils.style-enforcers.RunnerOpts
--- @param command string
--- @param argument table The command's only argument
--- @return nil
function M.execute_command(opts, command, argument)
  local params = { command = command, arguments = { argument } }
  opts.client:request('workspace/executeCommand', params, function(err)
    opts.on_done(not err, err and err.message)
  end, opts.bufnr)
end

--- Write the buffer if it has unsaved changes, returning ok, err rather than throwing: an
--- unwritable buffer (E32, E45, E212) would escape the async pipeline and leak the buffer lock
--- @param bufnr integer
--- @return boolean ok
--- @return string? err
function M.write(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return true
  end

  return pcall(vim.api.nvim_buf_call, bufnr, vim.cmd.update)
end

return M
