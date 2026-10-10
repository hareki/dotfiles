--- @class chrome.lualine.components.snacks-image
local M = {}

local image_icon = Conf.icons.editor.IMAGE .. ' '

-- vim.treesitter.query.get is memoized, but in a GC-weak cache: after any
-- collection the next lookup re-scans the runtimepath (and recompiles the
-- query), which is too slow for a per-redraw path. Pin the answer here.
--- @type table<string, boolean | 'no-parser'>
local lang_has_images_query = {}

-- A parser installed mid-session takes effect on the next FileType (`:edit`), so
-- that is when a language's missing-parser answer gets looked up again
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('chrome.lualine.snacks-image', { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and lang_has_images_query[lang] == 'no-parser' then
      lang_has_images_query[lang] = nil
    end
  end,
})

--- @param lang string
--- @return boolean
local function has_images_query(lang)
  local has = lang_has_images_query[lang]
  if has == nil then
    -- query.get throws when snacks ships an `images` query for a language whose
    -- parser isn't installed (vue, svelte, typst, ...); that would break every redraw
    local ok, query = pcall(vim.treesitter.query.get, lang, 'images')
    has = ok and query ~= nil or (not ok and 'no-parser')
    lang_has_images_query[lang] = has
  end
  return has == true
end

--- @class chrome.lualine.components.snacks-image.Cache
--- @field buf integer
--- @field tick integer
--- @field row integer
--- @field col integer
--- @field has_image boolean
local cache = {
  buf = -1,
  tick = -1,
  row = -1,
  col = -1,
  has_image = false,
}

--- @param buf integer
--- @return boolean
local function mermaid_has_content(buf)
  if vim.api.nvim_buf_line_count(buf) > 1 then
    return true
  end
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  return first ~= nil and first ~= ''
end

--- Returns true when `gi` would render an image at the current cursor position.
--- Mirrors the branching in `core.snacks.utils.image.hover_image`.
--- @return boolean
function M.cond()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  if ft == 'mermaid' then
    return mermaid_has_content(buf)
  end

  -- Skip buffers whose language has no snacks `images` query (json, yaml, help, ...):
  -- nothing can match there, so don't pay the per-cursor-move treesitter work below.
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang or not has_images_query(lang) then
    return false
  end

  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  if cache.buf == buf and cache.tick == tick and cache.row == row and cache.col == col then
    return cache.has_image
  end

  cache.buf = buf
  cache.tick = tick
  cache.row = row
  cache.col = col
  -- Reset eagerly so a stale `true` is never displayed after the cursor leaves
  -- an image. `at_cursor` parses asynchronously on nvim 0.11.4+, so the callback
  -- fires after this redraw; refresh the statusline once the real answer lands.
  cache.has_image = false

  Snacks.image.doc.at_cursor(function(src)
    -- The cursor may have moved during the async gap; don't attribute this
    -- result to a newer position
    if cache.buf ~= buf or cache.tick ~= tick or cache.row ~= row or cache.col ~= col then
      return
    end

    local has_image = src ~= nil
    if has_image ~= cache.has_image then
      cache.has_image = has_image
      UI.statusline.refresh()
    end
  end)

  return cache.has_image
end

--- @return string
function M.get()
  return image_icon
end

return M
