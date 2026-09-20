--- @class features.diagnostics.eagle.utils.pretty-ts-errors
local M = {}

M.state = {
  executable_path = 'pretty-ts-errors-markdown',
  cli_unavailable = false, -- Set on spawn failure so we never re-pay a failed spawn
  max_cache_entries = 512,
  cache = {}, -- key -> { value, from_cli, hits }
  cache_size = 0,
  supported_sources = {
    ts = true, -- What vtsls actually reports as diagnostic.source
    tsserver = true,
    typescript = true,
    ['typescript-tools'] = true,
    vtsls = true,
    ['typescript-language-server'] = true,
  },
}

local function trim_trailing_whitespace(text)
  return (text or ''):gsub('%s*$', '')
end

--- Read a field of the raw LSP diagnostic that Neovim keeps under user_data.lsp
local function lsp_field(diagnostic, key)
  return vim.tbl_get(diagnostic, 'user_data', 'lsp', key)
end

local function get_source(diagnostic)
  return diagnostic.source or lsp_field(diagnostic, 'source')
end

local function is_typescript_diagnostic(diagnostic)
  return M.state.supported_sources[get_source(diagnostic)] or type(diagnostic.code) == 'number'
end

local function normalize_range(diagnostic)
  local range = diagnostic.range or lsp_field(diagnostic, 'range')
  if range and range.start and range['end'] then
    return {
      start = { line = range.start.line or 0, character = range.start.character or 0 },
      ['end'] = { line = range['end'].line or 0, character = range['end'].character or 0 },
    }
  end
  local sl = diagnostic.lnum or 0
  local sc = diagnostic.col or 0
  local el = diagnostic.end_lnum or sl
  local ec = diagnostic.end_col or (sc + 1)

  return {
    start = { line = sl, character = sc },
    ['end'] = { line = el, character = ec },
  }
end

local function get_code(diagnostic)
  if diagnostic.code ~= nil then
    return diagnostic.code
  end

  return lsp_field(diagnostic, 'code')
end

local function get_severity(diagnostic)
  return diagnostic.severity or lsp_field(diagnostic, 'severity') or 1
end

local function build_cli_input(diagnostic)
  local related = diagnostic.relatedInformation
    or diagnostic.related
    or lsp_field(diagnostic, 'relatedInformation')

  return {
    range = normalize_range(diagnostic),
    message = diagnostic.message or '',
    code = get_code(diagnostic),
    severity = get_severity(diagnostic),
    source = get_source(diagnostic) or 'tsserver',
    relatedInformation = related or {},
  }
end

-- Key only over the fields that change the CLI's output, verified empirically:
-- identical input with different ranges or relatedInformation produces identical
-- markdown, while severity changes the header icon. Keying on range would turn
-- every line shift above the error into a miss, and each miss is a synchronous
-- ~200ms CLI spawn.
local function compute_cache_key(diagnostic)
  local parts = {
    get_source(diagnostic) or '',
    tostring(get_code(diagnostic) or ''),
    tostring(get_severity(diagnostic)),
    diagnostic.message or '',
  }

  return table.concat(parts, '\31')
end

local function maybe_evict_cache()
  if M.state.cache_size <= M.state.max_cache_entries then
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

  local cmd = { M.state.executable_path, '-i', json_text }
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

  -- vim.system throws on spawn failure: the CLI not being installed, but also
  -- a JSON arg exceeding the OS arg limit, which this stdin form handles.
  -- So only latch cli_unavailable when the stdin form throws too.
  local ok, result = pcall(function()
    return vim.system({ M.state.executable_path }, { text = true, stdin = json_text }):wait()
  end)
  if not ok then
    M.state.cli_unavailable = true
    return nil
  end

  return cli_markdown(result)
end

-- Eagle formats a line's diagnostics one after another, and every cache miss
-- blocks on a CLI spawn. So a miss spawns the CLI for all of the line's
-- uncached diagnostics from the same source at once: the popup then waits
-- about as long as the slowest spawn instead of their sum, and eagle's calls
-- for the rest of the line hit the cache.
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
    local source = get_source(diagnostic)
    for _, d in ipairs(vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })) do
      if get_source(d) == source then
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
  if type(md) ~= 'string' or md == '' then
    return md
  end
  local first_nl = md:find('\n', 1, true)
  if not first_nl then
    return md
  end
  local rest = md:sub(first_nl + 1)
  rest = rest:gsub('^\r?\n', '', 1) -- Remove one extra blank line if present

  return rest
end

--- Format a TypeScript diagnostic into pretty markdown using pretty-ts-errors-markdown CLI
--- Caches CLI output (evicting the least-hit entry past the cap) to avoid
--- redundant CLI calls for repeated diagnostics, and formats a miss's whole line at once.
--- @param diagnostic table The vim.Diagnostic object to format
--- @param opts? { href?: boolean } Options (href: keep CLI header with links)
--- @return string markdown The formatted markdown message
function M.format(diagnostic, opts)
  if type(diagnostic) ~= 'table' or not diagnostic.message then
    return ''
  end

  if not is_typescript_diagnostic(diagnostic) then
    -- Not a TS diagnostic, just return the original message.
    return diagnostic.message
  end

  local key = compute_cache_key(diagnostic)
  local entry = cache_get(key) or format_line(diagnostic)[key]
  local md = entry.value

  -- Only the CLI's markdown carries a header line; stripping the raw-message
  -- fallback would delete the first line of the actual error text
  if entry.from_cli and not (opts and opts.href) then
    md = strip_cli_header(md)
  end

  return md
end

return M
