--- @class features.diagnostics.eagle.utils.pretty-ts-errors
local M = {}

local EXECUTABLE = 'pretty-ts-errors-markdown'
local MAX_CACHE_ENTRIES = 512

M.state = {
  cli_unavailable = false, -- Set on spawn failure so we never re-pay a failed spawn
  cache = {}, -- key -> { value, from_cli, hits }
  cache_size = 0,
}

local function trim_trailing_whitespace(text)
  return (text:gsub('%s*$', ''))
end

--- Read a field of the raw LSP diagnostic that Neovim keeps under user_data.lsp
local function lsp_field(diagnostic, key)
  return vim.tbl_get(diagnostic, 'user_data', 'lsp', key)
end

--- @param diagnostic vim.Diagnostic
local function build_cli_input(diagnostic)
  return {
    range = lsp_field(diagnostic, 'range'),
    message = diagnostic.message,
    code = diagnostic.code,
    severity = diagnostic.severity,
    source = diagnostic.source,
    relatedInformation = lsp_field(diagnostic, 'relatedInformation') or {},
  }
end

-- Key only on fields that change the CLI's output (not range or relatedInformation): keying on
-- range would make every line shift above the error a miss, each a synchronous ~200ms spawn
local function compute_cache_key(diagnostic)
  local parts = {
    diagnostic.source,
    tostring(diagnostic.code or ''),
    tostring(diagnostic.severity),
    diagnostic.message,
  }

  return table.concat(parts, '\31')
end

local function maybe_evict_cache()
  if M.state.cache_size <= MAX_CACHE_ENTRIES then
    return
  end
  local lowest_key, lowest_hits
  for k, v in pairs(M.state.cache) do
    if not lowest_hits or v.hits < lowest_hits then
      lowest_hits, lowest_key = v.hits, k
    end
  end
  if lowest_key then
    M.state.cache[lowest_key] = nil
    M.state.cache_size = M.state.cache_size - 1
  end
end

local function cache_get(key)
  local e = M.state.cache[key]
  if e then
    e.hits = e.hits + 1
    return e
  end
end

--- @return { value: string, from_cli: boolean, hits: integer } entry
local function cache_set(key, value, from_cli)
  if not M.state.cache[key] then
    M.state.cache_size = M.state.cache_size + 1
  end
  local entry = { value = value, from_cli = from_cli, hits = 1 }
  M.state.cache[key] = entry
  maybe_evict_cache()

  return entry
end

--- @param result? vim.SystemCompleted
--- @return string? markdown
local function cli_markdown(result)
  if result and result.code == 0 and result.stdout and #result.stdout > 0 then
    return trim_trailing_whitespace(result.stdout)
  end
end

--- Start the CLI on one input without waiting for it
--- @param json_text string
--- @return vim.SystemObj? handle nil when the spawn failed or the CLI is unavailable
local function spawn_cli(json_text)
  if M.state.cli_unavailable then
    return nil
  end

  local cmd = { EXECUTABLE, '-i', json_text }
  local ok, handle = pcall(vim.system, cmd, { text = true })
  return ok and handle or nil
end

--- Wait for a spawn_cli run, retrying through stdin when the argument form failed
--- @param handle? vim.SystemObj
--- @param json_text string
--- @return string? markdown
local function collect_cli(handle, json_text)
  local markdown = handle and cli_markdown(handle:wait())
  if markdown or M.state.cli_unavailable then
    return markdown
  end

  -- vim.system also throws for a JSON arg past the OS arg limit, which this stdin form handles,
  -- so latch cli_unavailable only when the stdin form throws too
  local ok, result = pcall(function()
    return vim.system({ EXECUTABLE }, { text = true, stdin = json_text }):wait()
  end)
  if not ok then
    M.state.cli_unavailable = true
    return nil
  end

  return cli_markdown(result)
end

-- Eagle formats a line's diagnostics one by one, so a miss spawns the CLI for all of the line's
-- uncached same-source diagnostics at once: the popup waits for the slowest, not their sum
--- @param diagnostic vim.Diagnostic The cache miss
--- @return table<string, { value: string, from_cli: boolean, hits: integer }> entries By cache key
local function format_line(diagnostic)
  local jobs = {}

  local function spawn(d)
    local key = compute_cache_key(d)
    if jobs[key] or M.state.cache[key] then
      return
    end

    local json_text = vim.json.encode(build_cli_input(d))
    jobs[key] = { message = d.message, json_text = json_text, handle = spawn_cli(json_text) }
  end

  spawn(diagnostic)
  if diagnostic.bufnr then
    for _, d in ipairs(vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })) do
      if d.source == diagnostic.source then
        spawn(d)
      end
    end
  end

  local entries = {}
  for key, job in pairs(jobs) do
    local markdown = collect_cli(job.handle, job.json_text)
    entries[key] = cache_set(key, markdown or job.message, markdown ~= nil)
  end

  return entries
end

-- Strip the first line (the header with links) + a single blank line after it.
local function strip_cli_header(md)
  local first_nl = md:find('\n', 1, true)
  if not first_nl then
    return md
  end
  local rest = md:sub(first_nl + 1)
  rest = rest:gsub('^\r?\n', '', 1)

  return rest
end

--- Pretty markdown for a TypeScript diagnostic via the pretty-ts-errors-markdown CLI, cached
--- (least-hit eviction past the cap); eagle calls it only for its `ts` source (eagle-nvim/init.lua)
--- @param diagnostic vim.Diagnostic
--- @return string markdown
function M.format(diagnostic)
  local key = compute_cache_key(diagnostic)
  local entry = cache_get(key) or format_line(diagnostic)[key]
  local md = entry.value

  -- Only the CLI's markdown carries a header line; stripping the raw-message
  -- fallback would delete the first line of the actual error text
  if entry.from_cli then
    md = strip_cli_header(md)
  end

  return md
end

return M
