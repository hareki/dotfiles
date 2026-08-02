local M = {}

local cache = {}

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
  local hit = cache[path]
  if hit ~= nil then
    return hit or nil
  end

  local ok, ft = pcall(vim.filetype.match, { filename = path, contents = content_lines })
  if not ok or not ft then
    -- Retry without contents: some filetype matchers error on odd content.
    ok, ft = pcall(vim.filetype.match, { filename = path })
    if not ok or not ft then
      cache[path] = false
      return nil
    end
  end

  local lang = parser_available(vim.treesitter.language.get_lang(ft) or ft)
  if not lang and ft:find(".", 1, true) then
    -- Dotted filetypes like "yaml.ansible": fall back to the base filetype.
    local base = ft:match("^([^.]+)")
    lang = parser_available(vim.treesitter.language.get_lang(base) or base)
  end

  cache[path] = lang or false
  return lang
end

return M
