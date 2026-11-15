-- What a renderer does with a request, from its line to the render reaching the client's file; the
-- daemon handles one after another, a one-shot (render.lua) just one. A request is one line:
--   <in>\t<out>\t<cols>\t<layout>\t<metadata>\t<cwd>
-- <in> holds the diff and <out> takes the render, both made by the client.
-- <metadata> is 1 when the render is to carry OSC 1717 records, 0 otherwise.
-- cwd comes last, the only field that may hold a tab, and takes the rest of the line.

local core = require('lib.core')

local M = {}

-- Renders keyed by input and options (an unstaged diff's index line names its worktree content):
-- lazygit re-requests a diff whenever the selection returns. The byte ceiling below binds first.
local CACHE_MAX = 24
-- Rendered ANSI runs ~5-8x its input, so a few large commits could pin tens of MB without this.
local CACHE_MAX_BYTES = 32 * 1024 * 1024
local cache, cache_bytes = {}, 0 -- least recently used first

local function cache_get(key)
  for i, e in ipairs(cache) do
    if e.key == key then
      table.insert(cache, table.remove(cache, i))
      return e.out
    end
  end
end

local function cache_put(key, out)
  if #out > CACHE_MAX_BYTES then
    return
  end
  cache[#cache + 1] = { key = key, out = out }
  cache_bytes = cache_bytes + #out
  while #cache > CACHE_MAX or cache_bytes > CACHE_MAX_BYTES do
    cache_bytes = cache_bytes - #table.remove(cache, 1).out
  end
end

-- Opens the client's file, never creates one: a client lazygit killed has removed its directory,
-- and nobody would remove an output written after that.
local function write_output(path, data)
  local f = io.open(path, 'r+b')
  if not f then
    return false
  end
  local written = f:write(data)
  return f:close() and written ~= nil
end

-- Every option core.render is handed takes part, so a new option can't be served another's render.
local function cache_key(input, opts)
  local parts = { vim.fn.sha256(input) }
  for name, value in vim.spairs(opts) do
    parts[#parts + 1] = name .. '=' .. tostring(value)
  end
  return table.concat(parts, '\0')
end

--- Render `infile` to `outfile` with core.render `opts`; true when the render reached `outfile`.
local function render_request(infile, outfile, opts)
  local f = io.open(infile, 'rb')
  if not f then
    return false
  end
  local input = f:read('*a')
  f:close()

  local key = cache_key(input, opts)
  local rendered = cache_get(key)
  if not rendered then
    local ok, result, cacheable = pcall(core.render, input, opts)
    rendered = ok and result or input
    if ok and cacheable then
      cache_put(key, rendered)
    end
  end

  return write_output(outfile, rendered)
end

--- Handle one request line: true when the render reached the client's file (the daemon's `ok`).
function M.handle(request)
  local infile, outfile, cols, layout, metadata, cwd =
    request:match('^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([01])\t(.*)$')
  if not infile then
    return false
  end
  -- Typed once here, so the cache key and the render see the same values.
  return render_request(infile, outfile, {
    cwd = cwd,
    cols = tonumber(cols),
    layout = layout,
    metadata = metadata == '1',
  })
end

return M
