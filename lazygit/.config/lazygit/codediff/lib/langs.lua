local M = {}

-- Capped and cleared wholesale (as layout.lua's filler runs are): the daemon lives up to an hour
-- and each distinct path adds an entry; a miss costs one vim.filetype.match again.
local CACHE_MAX = 512
local cache = {}

local function remember(key, lang)
  if vim.tbl_count(cache) >= CACHE_MAX then
    cache = {}
  end
  cache[key] = lang
  return lang or nil
end

local function parser_available(lang)
  -- add() returns nil for a missing parser; it only raises on a malformed name or a broken library.
  local ok, loaded = pcall(vim.treesitter.language.add, lang)
  return ok and loaded and lang or nil
end

--- A path's loadable treesitter language (content lines help detection), or nil to render plain.
function M.lang_for(path, content_lines)
  -- Keyed by path and a bounded first-line fingerprint: shebangs make a path's language differ
  -- across repos and with or without content, and a first line can be the whole file.
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

  -- A dotted filetype ("typescript.glimmer") may name a parserless language: fall back to its base.
  local get_lang = vim.treesitter.language.get_lang
  local lang = parser_available(get_lang(ft)) or parser_available(get_lang(ft:match('^[^.]+')))

  return remember(key, lang or false)
end

return M
