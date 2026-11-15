-- What a renderer does with a request, from the line a client sent to whether
-- the render it asked for reached the client's output file. The daemon handles
-- one after another; a one-shot (render.lua) is started for one.
--
-- One request is one line, tab separated:
--   <in>\t<out>\t<cols>\t<layout>\t<metadata>\t<cwd>
-- <in> holds the diff and <out> takes the render, both made by the client.
-- <metadata> is 1 when the render is to carry OSC 1717 records, 0 otherwise.
-- cwd comes last because it is the only field that can legitimately contain a
-- tab, so it simply takes the rest of the line.

local core = require('lib.core')

local M = {}

-- Rendered-output cache: browsing commits in lazygit re-requests the same diff
-- every time the selection returns to it, and the expensive renders (large
-- commits) are exactly the ones worth never paying twice. Keyed by the full
-- input plus everything else that shapes the output, which holds for an unstaged
-- diff too: its index line names the worktree content it shows. A daemon recycle
-- (parser/plugin/source updates) drops the cache with the process.
-- Sized so the byte ceiling below stays the binding constraint rather than this
-- count: a single file's diff renders to well under a megabyte, so 32 MB is
-- room for dozens, and a commit-sized render still leaves room for twenty.
-- A lookup is an O(n) scan, trivial at this size.
local CACHE_MAX = 24
-- Rendered ANSI runs ~5-8x its input (tinted rows pad out to the full width),
-- so a handful of large-commit renders can pin tens of MB for the daemon's
-- lifetime; the byte ceiling bounds memory where the entry count cannot.
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

-- Opens the file the client made rather than creating one, in the private
-- directory the client made for it. A client that lazygit killed mid-render has
-- already removed that directory, and nobody is left to remove an output
-- written after that, so a render that outlives its client has to fail here.
local function write_output(path, data)
  local f = io.open(path, 'r+b')
  if not f then
    return false
  end
  local written = f:write(data)
  return f:close() and written ~= nil
end

-- The cache key for rendering `input` with `opts`. Every option core.render is
-- handed takes part, so an option added later cannot be left out of the key and
-- have a render made for other options served in its place.
local function cache_key(input, opts)
  local parts = { vim.fn.sha256(input) }
  for name, value in vim.spairs(opts) do
    parts[#parts + 1] = name .. '=' .. tostring(value)
  end
  return table.concat(parts, '\0')
end

--- Render `infile` to `outfile` with core.render `opts`, returning whether the
--- render reached `outfile`.
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

--- Handle one request line. True when the render reached the client's output
--- file, which is what the daemon answers `ok` for; false for a line that is
--- not a request, or files that are not there.
function M.handle(request)
  local infile, outfile, cols, layout, metadata, cwd =
    request:match('^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([01])\t(.*)$')
  if not infile then
    return false
  end
  -- The wire carries every field as a string; convert once here rather than at
  -- each use, so the cache key and the render see the same typed value.
  return render_request(infile, outfile, {
    cwd = cwd,
    cols = tonumber(cols),
    layout = layout,
    metadata = metadata == '1',
  })
end

return M
