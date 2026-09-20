local M = {}

-- Capped and cleared wholesale rather than evicted one entry at a time -- the
-- shape lib/layout.lua already uses for its filler runs. The daemon serves for
-- up to an hour and every distinct path (see the key below) adds an entry, so
-- browsing a monorepo's history would otherwise only ever grow this. A few
-- hundred covers the files a session moves between; past that a render pays one
-- vim.filetype.match again, which is what the entry cost to make.
local CACHE_MAX = 512
local cache, n_cached = {}, 0

local function remember(key, lang)
  if n_cached >= CACHE_MAX then
    cache, n_cached = {}, 0
  end
  cache[key] = lang
  n_cached = n_cached + 1
  return lang or nil
end

local function parser_available(lang)
  local ok = pcall(vim.treesitter.language.add, lang)
  return ok and lang or nil
end

--- Resolve a path (plus optional content lines) to a loadable treesitter
--- language, or nil when the file should render without syntax highlighting.
function M.lang_for(path, content_lines)
  if not path then
    return nil
  end
  -- The daemon is per-user, not per-repo, and lives for up to an hour, so the
  -- path alone is not a safe key: content-based detection (shebangs) makes the
  -- same relative path resolve differently across repos, and between a render
  -- that had the file's content and one that did not.
  --
  -- Only a bounded fingerprint of the first line goes into the key. Embedding
  -- the line itself would pin it in this never-evicted cache for the daemon's
  -- lifetime, and a first line can be the whole file (a minified bundle, up to
  -- max_blob_bytes); the detectors only ever look at its head anyway.
  local sample = (content_lines and content_lines[1]) or ''
  local key = path .. '\0' .. #sample .. '\0' .. sample:sub(1, 256)
  local hit = cache[key]
  if hit ~= nil then
    return hit or nil
  end

  local ok, ft = pcall(vim.filetype.match, { filename = path, contents = content_lines })
  if not ok or not ft then
    -- Retry without contents: some filetype matchers error on odd content.
    ok, ft = pcall(vim.filetype.match, { filename = path })
    if not ok or not ft then
      return remember(key, false)
    end
  end

  local lang = parser_available(vim.treesitter.language.get_lang(ft) or ft)
  if not lang and ft:find('.', 1, true) then
    -- Dotted filetypes like "yaml.ansible": fall back to the base filetype.
    local base = ft:match('^([^.]+)')
    lang = parser_available(vim.treesitter.language.get_lang(base) or base)
  end

  return remember(key, lang or false)
end

return M
