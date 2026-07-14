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

local function is_typescript_diagnostic(diagnostic)
  local source = diagnostic.source
  if not source and diagnostic.user_data and diagnostic.user_data.lsp then
    source = diagnostic.user_data.lsp.source
  end

  return M.state.supported_sources[source] or type(diagnostic.code) == 'number'
end

local function normalize_range(diagnostic)
  local range = diagnostic.range
  if not range and diagnostic.user_data and diagnostic.user_data.lsp then
    range = diagnostic.user_data.lsp.range
  end
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
  if diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.code ~= nil then
    return diagnostic.user_data.lsp.code
  end

  return nil
end

local function get_severity(diagnostic)
  return diagnostic.severity
    or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.severity)
    or 1
end

local function build_cli_input(diagnostic)
  return {
    range = normalize_range(diagnostic),
    message = diagnostic.message or '',
    code = get_code(diagnostic),
    severity = get_severity(diagnostic),
    source = diagnostic.source
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.source)
      or 'tsserver',
    relatedInformation = diagnostic.relatedInformation
      or diagnostic.related
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.relatedInformation)
      or {},
  }
end

-- Key only over the fields that change the CLI's output — verified empirically:
-- identical input with different ranges or relatedInformation produces identical
-- markdown, while severity changes the header icon. Keying on range would turn
-- every line shift above the error into a miss, and each miss is a synchronous
-- ~200ms CLI spawn.
local function compute_cache_key(diagnostic)
  local parts = {
    diagnostic.source
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.source)
      or '',
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

local function cache_set(key, value, from_cli)
  if not M.state.cache[key] then
    M.state.cache_size = M.state.cache_size + 1
  end
  M.state.cache[key] = { value = value, from_cli = from_cli, hits = 1 }
  maybe_evict_cache()
end

local function run_cli(input_object)
  if M.state.cli_unavailable then
    return nil
  end

  local json_text = vim.json.encode(input_object)
  local exe = M.state.executable_path

  -- vim.system throws on spawn failure: the CLI not being installed, but also
  -- a JSON arg exceeding the OS arg limit, which the stdin form below handles.
  -- So only latch cli_unavailable when the stdin form throws too.
  local arg_ok, arg_result = pcall(function()
    return vim.system({ exe, '-i', json_text }, { text = true }):wait()
  end)
  if
    arg_ok
    and arg_result
    and arg_result.code == 0
    and arg_result.stdout
    and #arg_result.stdout > 0
  then
    return trim_trailing_whitespace(arg_result.stdout)
  end

  local stdin_ok, stdin_result = pcall(function()
    return vim.system({ exe }, { text = true, stdin = json_text }):wait()
  end)
  if not stdin_ok then
    M.state.cli_unavailable = true
    return nil
  end
  if
    stdin_result
    and stdin_result.code == 0
    and stdin_result.stdout
    and #stdin_result.stdout > 0
  then
    return trim_trailing_whitespace(stdin_result.stdout)
  end

  return nil
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
--- redundant CLI calls for repeated diagnostics.
--- @param diagnostic table The vim.Diagnostic object to format
--- @param opts? { href?: boolean } Options (href: keep CLI header with links)
--- @return string markdown The formatted markdown message
function M.format(diagnostic, opts)
  if type(diagnostic) ~= 'table' or not diagnostic.message then
    return ''
  end

  if not is_typescript_diagnostic(diagnostic) then
    -- Not a TS diagnostic — just return the original message.
    return diagnostic.message
  end

  local key = compute_cache_key(diagnostic)
  local entry = cache_get(key)

  local md, from_cli
  if entry then
    md, from_cli = entry.value, entry.from_cli
  else
    local cli_md = run_cli(build_cli_input(diagnostic))
    from_cli = cli_md ~= nil
    md = cli_md or diagnostic.message
    cache_set(key, md, from_cli)
  end

  -- Only the CLI's markdown carries a header line; stripping the raw-message
  -- fallback would delete the first line of the actual error text
  if from_cli and not (opts and opts.href) then
    md = strip_cli_header(md)
  end

  return md
end

return M
