--- @class utils.style-enforcers.engine.RunOpts
--- @field bufnr integer
--- @field on_start fun(name: string, idx: integer, total: integer)
--- @field on_done fun(name: string, ok: boolean, err?: string) Called after each enforcer
--- @field on_complete fun(ok: boolean) Called once when the run ends: after the last enforcer, or the first failed one

--- @class utils.style-enforcers.engine
local M = {}

--- Error a runner reports when the buffer was edited while its request was in flight
M.BUFFER_CHANGED = 'buffer changed while running'

--- @alias utils.style-enforcers.engine.RunnerOpts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @alias utils.style-enforcers.engine.Runner fun(opts: utils.style-enforcers.engine.RunnerOpts)

--- @class utils.style-enforcers.engine.Entry
--- @field name string LSP client the runner drives, doubling as the enforcer name
--- @field runner utils.style-enforcers.engine.Runner

--- @type utils.style-enforcers.engine.Entry[]
local entries = {}

--- Register an enforcer for buffers with the LSP client `name` attached, run in registration order
--- @param name string
--- @param runner utils.style-enforcers.engine.Runner
--- @return nil
function M.register(name, runner)
  entries[#entries + 1] = { name = name, runner = runner }
end

--- Registered enforcers whose client is attached to a buffer, in registration order
--- @param bufnr integer
--- @return utils.style-enforcers.engine.Entry[]
local function entries_for_buf(bufnr)
  return vim.tbl_filter(function(entry)
    return #vim.lsp.get_clients({ name = entry.name, bufnr = bufnr }) > 0
  end, entries)
end

--- Run the matched enforcers sequentially
--- @param matched utils.style-enforcers.engine.Entry[]
--- @param opts utils.style-enforcers.engine.RunOpts
--- @param idx integer
local function run_next(matched, opts, idx)
  local entry = matched[idx]
  if not entry then
    return opts.on_complete(true)
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
      opts.on_complete(false)
    end
  end

  -- Looked up again rather than kept from the match: it may have detached meanwhile
  local client = vim.lsp.get_clients({ name = entry.name, bufnr = opts.bufnr })[1]
  if not client then
    return on_done(false, entry.name .. ' client missing')
  end

  entry.runner({ bufnr = opts.bufnr, client = client, on_done = on_done })
end

--- Run every registered enforcer that applies to the buffer
--- @param opts utils.style-enforcers.engine.RunOpts
--- @return nil
function M.run_for_buf(opts)
  run_next(entries_for_buf(opts.bufnr), opts, 1)
end

--- Send a workspace/executeCommand for a runner, reporting the server's error to its on_done
--- @param opts utils.style-enforcers.engine.RunnerOpts
--- @param command string
--- @param argument table The command's only argument
--- @return nil
function M.execute_command(opts, command, argument)
  local params = { command = command, arguments = { argument } }
  opts.client:request('workspace/executeCommand', params, function(err)
    opts.on_done(not err, err and err.message)
  end, opts.bufnr)
end

--- Send a request for a runner and pass the reply to on_result, unless the server errors or the
--- buffer changed in flight: edits from the reply's unversioned positions would corrupt the text
--- @param opts utils.style-enforcers.engine.RunnerOpts
--- @param method vim.lsp.protocol.Method.ClientToServer.Request
--- @param params table
--- @param on_result fun(result: any)
--- @return nil
function M.request(opts, method, params, on_result)
  local bufnr = opts.bufnr
  -- changedtick rather than the reply's ctx.version, which an autoread reload leaves unchanged
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  opts.client:request(method, params, function(err, result)
    if err then
      return opts.on_done(false, err.message)
    end

    if
      not vim.api.nvim_buf_is_valid(bufnr)
      or vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick
    then
      return opts.on_done(false, M.BUFFER_CHANGED)
    end

    on_result(result)
  end, bufnr)
end

return M
