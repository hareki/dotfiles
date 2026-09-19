--- @class utils.style-enforcers.RunOpts
--- @field bufnr integer
--- @field on_start fun(name: string, idx: integer, total: integer) | nil
--- @field on_done  fun(name: string, ok: boolean, err?: string) | nil

--- @class utils.style-enforcers.engine
local M = {}

--- @class utils.style-enforcers.Entry
--- @field name string
--- @field filetypes string[]
--- @field runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) })
--- @field order integer Smaller runs first
--- @field seq integer Registration sequence, tiebreaker for a stable sort
--- @field client? string LSP client the runner drives

local DEFAULT_ORDER = 100

--- @type utils.style-enforcers.Entry[]
local entries = {}
local seq = 0

--- Register a enforcer with its supported filetypes
--- @param name string Unique enforcer name
--- @param filetypes string[] List of filetypes this enforcer supports
--- @param runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) }) The enforcer function
--- @param opts? { order?: integer, client?: string } `order` sets run position: smaller runs first (default 100). Use a lower value for a formatter step that must run ahead of lint-fix steps. `client` limits the enforcer to buffers that LSP client is attached to, so projects that never start the server (or files outside its root) skip the step.
--- @return nil
function M.register(name, filetypes, runner, opts)
  seq = seq + 1
  entries[#entries + 1] = {
    name = name,
    filetypes = filetypes,
    runner = runner,
    order = (opts and opts.order) or DEFAULT_ORDER,
    seq = seq,
    client = opts and opts.client,
  }
end

--- Registered enforcers that apply to a buffer, sorted by `order`, then registration order
--- @param bufnr integer
--- @return utils.style-enforcers.Entry[]
local function entries_for_buf(bufnr)
  local ft = vim.bo[bufnr].filetype
  local matched = vim.tbl_filter(function(entry)
    return vim.list_contains(entry.filetypes, ft)
      and (not entry.client or #vim.lsp.get_clients({ name = entry.client, bufnr = bufnr }) > 0)
  end, entries)

  table.sort(matched, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.seq < b.seq
  end)

  return matched
end

--- Get the names of the enforcers that apply to a buffer (sorted by `order`, then registration order)
--- @param bufnr integer
--- @return string[] names
function M.names_for_buf(bufnr)
  return vim.tbl_map(function(entry)
    return entry.name
  end, entries_for_buf(bufnr))
end

--- Internal: run the matched enforcers sequentially
--- @param matched utils.style-enforcers.Entry[]
--- @param opts utils.style-enforcers.RunOpts
--- @param idx integer
local function run_next(matched, opts, idx)
  local entry = matched[idx]
  if not entry then
    return
  end

  if opts.on_start then
    opts.on_start(entry.name, idx, #matched)
  end

  entry.runner({
    bufnr = opts.bufnr,
    on_done = function(ok, err)
      if opts.on_done then
        opts.on_done(entry.name, ok, err)
      end
      run_next(matched, opts, idx + 1)
    end,
  })
end

--- Run every registered enforcer that applies to the buffer
--- @param opts utils.style-enforcers.RunOpts Options with bufnr, on_start, on_done callbacks
--- @return nil
function M.run_for_buf(opts)
  local bufnr = opts.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    if opts.on_done then
      opts.on_done('none', false, 'invalid buffer')
    end
    return
  end

  local matched = entries_for_buf(bufnr)

  if #matched == 0 and opts.on_done then
    opts.on_done('none', true) -- no enforcers, no error
    return
  end

  run_next(matched, opts, 1)
end

return M
