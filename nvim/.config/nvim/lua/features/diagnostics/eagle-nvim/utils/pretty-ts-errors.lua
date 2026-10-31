--- @class features.diagnostics.eagle.utils.pretty-ts-errors
local M = {}

local EXECUTABLE = 'pretty-ts-errors-markdown'
local MAX_CACHE_ENTRIES = 512

M.state = {
  cli_unavailable = false, -- Set on spawn failure so we never re-pay a failed spawn
  cache = {}, -- key -> markdown
  cache_size = 0,
}

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

local function cache_set(key, markdown)
  if M.state.cache_size >= MAX_CACHE_ENTRIES then
    M.state.cache, M.state.cache_size = {}, 0
  end

  M.state.cache[key] = markdown
  M.state.cache_size = M.state.cache_size + 1
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

--- @param result vim.SystemCompleted
--- @return string? markdown
local function cli_markdown(result)
  if result.code == 0 and result.stdout ~= '' then
    return strip_cli_header(vim.trim(result.stdout))
  end
end

--- Start the CLI without waiting for it, through stdin: a long JSON argument could hit ARG_MAX
--- @param json_text string
--- @return vim.SystemObj? handle nil when the CLI is unavailable
local function spawn_cli(json_text)
  if M.state.cli_unavailable then
    return nil
  end

  local ok, handle = pcall(vim.system, { EXECUTABLE }, { text = true, stdin = json_text })
  if ok then
    return handle
  end
  M.state.cli_unavailable = true
end

-- Eagle formats a line's diagnostics one by one, so a miss spawns the CLI for all of the line's
-- uncached same-source diagnostics at once: the popup waits for the slowest, not their sum
--- @param diagnostic vim.Diagnostic The cache miss
--- @return table<string, string> markdown By cache key
local function format_line(diagnostic)
  local jobs = {}

  local function spawn(d)
    local key = compute_cache_key(d)
    if jobs[key] or M.state.cache[key] then
      return
    end

    jobs[key] = { message = d.message, handle = spawn_cli(vim.json.encode(build_cli_input(d))) }
  end

  spawn(diagnostic)
  for _, d in ipairs(vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })) do
    if d.source == diagnostic.source then
      spawn(d)
    end
  end

  local results = {}
  for key, job in pairs(jobs) do
    results[key] = job.handle and cli_markdown(job.handle:wait()) or job.message
    cache_set(key, results[key])
  end

  return results
end

--- Pretty markdown for a TypeScript diagnostic via the pretty-ts-errors-markdown CLI, cached
--- (wiped at the cap); eagle calls it only for its `ts` source (eagle-nvim/init.lua)
--- @param diagnostic vim.Diagnostic
--- @return string markdown
function M.format(diagnostic)
  local key = compute_cache_key(diagnostic)
  return M.state.cache[key] or format_line(diagnostic)[key]
end

return M
