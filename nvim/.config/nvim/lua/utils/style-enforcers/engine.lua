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

local DEFAULT_ORDER = 100

--- @type utils.style-enforcers.Entry[]
local entries = {}
local seq = 0

--- Register a enforcer with its supported filetypes
--- @param name string Unique enforcer name
--- @param filetypes string[] List of filetypes this enforcer supports
--- @param runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) }) The enforcer function
--- @param opts? { order?: integer } `order` sets run position — smaller runs first (default 100). Use a lower value for a formatter step that must run ahead of lint-fix steps.
--- @return nil
function M.register(name, filetypes, runner, opts)
  seq = seq + 1
  entries[#entries + 1] = {
    name = name,
    filetypes = filetypes,
    runner = runner,
    order = (opts and opts.order) or DEFAULT_ORDER,
    seq = seq,
  }
end

--- Register an LSP-backed enforcer once a client of its server first attaches,
--- so projects that never start that server don't get its step
--- @param name string LSP server name, doubling as the enforcer name
--- @param filetypes string[] List of filetypes this enforcer supports
--- @param runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) }) The enforcer function
--- @param opts? { order?: integer } See M.register
--- @return nil
function M.register_on_attach(name, filetypes, runner, opts)
  local registered = false
  -- Fires once per (client, buffer) attach; only the first one registers
  Snacks.util.lsp.on({ name = name }, function()
    if registered then
      return
    end

    registered = true
    M.register(name, filetypes, runner, opts)
  end)
end

--- Registered enforcers for a filetype, sorted by `order`, then registration order
--- @param ft string The filetype to look up
--- @return utils.style-enforcers.Entry[]
local function entries_for_filetype(ft)
  local matched = vim.tbl_filter(function(entry)
    return vim.list_contains(entry.filetypes, ft)
  end, entries)

  table.sort(matched, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.seq < b.seq
  end)

  return matched
end

--- Get registered enforcer names for a filetype (sorted by `order`, then registration order)
--- @param ft string The filetype to look up
--- @return string[] names List of enforcer names that support this filetype
function M.names_for_filetype(ft)
  return vim.tbl_map(function(entry)
    return entry.name
  end, entries_for_filetype(ft))
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

--- Auto-run all registered enforcers matching the buffer's filetype
--- @param opts utils.style-enforcers.RunOpts Options with bufnr, on_start, on_done callbacks
--- @return nil
function M.run_by_ft(opts)
  local bufnr = opts.bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    if opts.on_done then
      opts.on_done('none', false, 'invalid buffer')
    end
    return
  end

  local matched = entries_for_filetype(vim.bo[bufnr].filetype)

  if #matched == 0 and opts.on_done then
    opts.on_done('none', true) -- no enforcers, no error
    return
  end

  run_next(matched, opts, 1)
end

return M
