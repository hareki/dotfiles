local M = {}

local state = {
  executable_path = 'pretty-ts-errors-markdown',
  max_cache_entries = 512,
  cache = {}, -- key -> { value, hits }
  supported_sources = {
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
  return state.supported_sources[source] or type(diagnostic.code) == 'number'
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

local function build_cli_input(diagnostic)
  return {
    range = normalize_range(diagnostic),
    message = diagnostic.message or '',
    code = get_code(diagnostic),
    severity = diagnostic.severity
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.severity)
      or 1,
    source = diagnostic.source
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.source)
      or 'tsserver',
    relatedInformation = diagnostic.relatedInformation
      or diagnostic.related
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.relatedInformation)
      or {},
  }
end

local function compute_cache_key(diagnostic)
  local r = normalize_range(diagnostic)
  local parts = {
    diagnostic.source
      or (diagnostic.user_data and diagnostic.user_data.lsp and diagnostic.user_data.lsp.source)
      or '',
    tostring(get_code(diagnostic) or ''),
    tostring(r.start.line),
    tostring(r.start.character),
    tostring(r['end'].line),
    tostring(r['end'].character),
    diagnostic.message or '',
  }
  return table.concat(parts, '\31')
end

local function maybe_evict_cache()
  local size = 0
  for _ in pairs(state.cache) do
    size = size + 1
  end
  if size <= state.max_cache_entries then
    return
  end
  local lowest_key, lowest_hits
  for k, v in pairs(state.cache) do
    if not lowest_hits or v.hits < lowest_hits then
      lowest_hits, lowest_key = v.hits, k
    end
  end
  if lowest_key then
    state.cache[lowest_key] = nil
  end
end

local function cache_get(key)
  local e = state.cache[key]
  if e then
    e.hits = e.hits + 1
    return e.value
  end
end

local function cache_set(key, value)
  state.cache[key] = { value = value, hits = 1 }
  maybe_evict_cache()
end

local function run_cli(input_object)
  local json_text = vim.json.encode(input_object)
  local exe = state.executable_path
  local res = vim.system({ exe, '-i', json_text }, { text = true }):wait()
  if res and res.code == 0 and res.stdout and #res.stdout > 0 then
    return trim_trailing_whitespace(res.stdout)
  end
  local res2 = vim.system({ exe }, { text = true, stdin = json_text }):wait()
  if res2 and res2.code == 0 and res2.stdout and #res2.stdout > 0 then
    return trim_trailing_whitespace(res2.stdout)
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
  -- remove one extra blank line if present
  rest = rest:gsub('^\r?\n', '', 1)
  return rest
end

function M.format(diagnostic, opts)
  if type(diagnostic) ~= 'table' or not diagnostic.message then
    return ''
  end

  if not is_typescript_diagnostic(diagnostic) then
    -- Not a TS diagnostic — just return the original message.
    return diagnostic.message
  end

  local key = compute_cache_key(diagnostic)
  local cached = cache_get(key)

  local md = cached
  if not md then
    md = run_cli(build_cli_input(diagnostic)) or diagnostic.message
    cache_set(key, md)
  end

  -- Only keep the CLI’s header line when opts.href == true
  if not (opts and opts.href) then
    md = strip_cli_header(md)
  end

  return md
end

return M
