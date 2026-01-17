---@class utils.linters.RunOpts
---@field bufnr integer
---@field on_start fun(name: string, idx: integer, total: integer) | nil
---@field on_done  fun(name: string, ok: boolean, err?: string) | nil

---@class utils.linters
local M = {}

---@class utils.linters.Entry
---@field name string
---@field filetypes string[]
---@field runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) })

---@type utils.linters.Entry[]
local entries = {} -- Preserve order of registration

---Register a linter with its supported filetypes
---@param name string Unique linter name
---@param filetypes string[] List of filetypes this linter supports
---@param runner fun(opts: { bufnr: integer, on_done: fun(ok: boolean, err?: string) }) The linter function
---@return nil
function M.register(name, filetypes, runner)
  entries[#entries + 1] = { name = name, filetypes = filetypes, runner = runner }
end

---Get registered linter names for a filetype (preserves registration order)
---@param ft string The filetype to look up
---@return string[] names List of linter names that support this filetype
function M.names_for_filetype(ft)
  local out = {}
  for _, entry in ipairs(entries) do
    for _, filetype in ipairs(entry.filetypes) do
      if filetype == ft then
        out[#out + 1] = entry.name
        break
      end
    end
  end
  return out
end

---Internal: run names sequentially
local function run_next(names, opts, idx)
  idx = idx or 1
  local name = names[idx]
  if not name then
    return
  end

  -- Find entry
  local runner
  for _, e in ipairs(entries) do
    if e.name == name then
      runner = e.runner
      break
    end
  end

  if not runner then
    if opts.on_done then
      opts.on_done(name, false, 'not registered')
    end
    return run_next(names, opts, idx + 1)
  end

  if opts.on_start then
    opts.on_start(name, idx, #names)
  end

  local function done(ok, err)
    if opts.on_done then
      opts.on_done(name, ok, err)
    end
    run_next(names, opts, idx + 1)
  end

  runner({ bufnr = opts.bufnr, on_done = done })
end

---Run a list of linters sequentially on a buffer
---@param names string[] List of linter names to run
---@param opts utils.linters.RunOpts Options with bufnr, on_start, on_done callbacks
---@return nil
function M.run(names, opts)
  run_next(names, opts, 1)
end

---Auto-run all registered linters matching the buffer's filetype
---@param opts utils.linters.RunOpts Options with bufnr, on_start, on_done callbacks
---@return nil
function M.run_by_ft(opts)
  local bufnr = opts.bufnr
  local ft = vim.bo[bufnr].filetype
  local names = M.names_for_filetype(ft)

  if #names == 0 and opts.on_done then
    opts.on_done('none', true) -- no linters, no error
    return
  end

  M.run(names, opts)
end

return M
