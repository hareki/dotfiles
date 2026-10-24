--- @class utils.style-enforcers.RunOpts
--- @field bufnr integer
--- @field on_start fun(name: string, idx: integer, total: integer) | nil
--- @field on_done  fun(name: string, ok: boolean, err?: string) | nil Called after each enforcer
--- @field on_complete fun() | nil Called once when the run ends: after the last enforcer, or the first failed one

--- @class utils.style-enforcers.engine
local M = {}

--- Error a runner reports when the buffer was edited while its request was in flight,
--- so the result no longer applies to it
M.BUFFER_CHANGED = 'buffer changed while running'

--- @alias utils.style-enforcers.Runner fun(opts: { bufnr: integer, client?: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) })

--- @class utils.style-enforcers.Entry
--- @field name string
--- @field filetypes string[]
--- @field runner utils.style-enforcers.Runner Gets the entry's LSP client, when it names one
--- @field client? string LSP client the runner drives

--- @type utils.style-enforcers.Entry[]
local entries = {}

--- Register an enforcer with its supported filetypes; enforcers run in registration order
--- @param name string Unique enforcer name
--- @param filetypes string[]
--- @param runner utils.style-enforcers.Runner
--- @param opts? { client?: string } `client`: skip buffers it's not attached to
--- @return nil
function M.register(name, filetypes, runner, opts)
  entries[#entries + 1] = {
    name = name,
    filetypes = filetypes,
    runner = runner,
    client = opts and opts.client,
  }
end

--- Registered enforcers that apply to a buffer, in registration order
--- @param bufnr integer
--- @return utils.style-enforcers.Entry[]
local function entries_for_buf(bufnr)
  local ft = vim.bo[bufnr].filetype
  return vim.tbl_filter(function(entry)
    return vim.list_contains(entry.filetypes, ft)
      and (not entry.client or #vim.lsp.get_clients({ name = entry.client, bufnr = bufnr }) > 0)
  end, entries)
end

--- Run the matched enforcers sequentially
--- @param matched utils.style-enforcers.Entry[]
--- @param opts utils.style-enforcers.RunOpts
--- @param idx integer
local function run_next(matched, opts, idx)
  local entry = matched[idx]
  if not entry then
    if opts.on_complete then
      opts.on_complete()
    end
    return
  end

  if opts.on_start then
    opts.on_start(entry.name, idx, #matched)
  end

  --- @param ok boolean
  --- @param err? string
  local function on_done(ok, err)
    if opts.on_done then
      opts.on_done(entry.name, ok, err)
    end

    -- A failed enforcer ends the run like a failed format step ends the pipeline (init.lua): after
    -- BUFFER_CHANGED, whoever is editing the buffer would race the remaining enforcers
    if ok then
      run_next(matched, opts, idx + 1)
    elseif opts.on_complete then
      opts.on_complete()
    end
  end

  -- Looked up again rather than kept from the match: it may have detached while the
  -- earlier enforcers ran
  local client = entry.client
    and vim.lsp.get_clients({ name = entry.client, bufnr = opts.bufnr })[1]
  if entry.client and not client then
    return on_done(false, entry.client .. ' client missing')
  end

  entry.runner({ bufnr = opts.bufnr, client = client, on_done = on_done })
end

--- Run every registered enforcer that applies to the buffer
--- @param opts utils.style-enforcers.RunOpts
--- @return nil
function M.run_for_buf(opts)
  run_next(entries_for_buf(opts.bufnr), opts, 1)
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
