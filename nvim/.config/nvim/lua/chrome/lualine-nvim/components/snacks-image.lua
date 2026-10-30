--- @class chrome.lualine.components.snacks-image
local M = {}

local image_icon = Conf.icons.editor.IMAGE .. ' '

-- vim.treesitter.query.get memoizes in a GC-weak cache, so after a collection it re-scans the
-- runtimepath and recompiles the query, too slow for a per-redraw path: pin the answer here
--- @type table<string, boolean>
local lang_has_images_query = {}

--- @param lang string A language with a loaded parser
--- @return boolean
local function has_images_query(lang)
  local has = lang_has_images_query[lang]
  if has == nil then
    -- query.get throws on a query that doesn't parse against the installed grammar, and that
    -- would break every redraw
    local ok, query = pcall(vim.treesitter.query.get, lang, 'images')
    has = ok and query ~= nil
    lang_has_images_query[lang] = has
  end
  return has
end

-- The images found in one buffer state. Cursor moves only test the cursor against them;
-- the treesitter query reruns when the buffer or its text changes
--- @class chrome.lualine.components.snacks-image.Cache
--- @field buf integer
--- @field tick integer
--- @field images snacks.image.match[] | nil nil while the query is in flight
local cache = {
  buf = -1,
  tick = -1,
  images = nil,
}

--- Whether an image covers the cursor, tested the way Snacks.image.doc.at_cursor does
--- @param images snacks.image.match[]
--- @param cursor integer[] (1,0)-indexed row and column
--- @return boolean
local function image_at(images, cursor)
  for _, image in ipairs(images) do
    local range = image.range
    if
      range
      and (
        (
          range[1] == range[3]
          and cursor[1] == range[1]
          and cursor[2] >= range[2]
          and cursor[2] <= range[4]
        ) or (range[1] ~= range[3] and cursor[1] >= range[1] and cursor[1] <= range[3])
      )
    then
      return true
    end
  end
  return false
end

--- @param buf integer
--- @return boolean
local function mermaid_has_content(buf)
  return vim.api.nvim_buf_line_count(buf) > 1
    or vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] ~= ''
end

--- Returns true when `gi` would render an image at the current cursor position.
--- Mirrors the branching in `features.preview.snacks.utils.hover_image`.
--- @return boolean
function M.cond()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].filetype == 'mermaid' then
    return mermaid_has_content(buf)
  end

  -- `gi` is a normal-mode key, while every insert/replace keystroke bumps the changedtick and
  -- would rerun the whole-buffer find() below (~2ms in an 850-line TSX file)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == 'i' or mode == 'R' then
    return false
  end

  -- Nothing can match without a parser (snacks ships `images` queries for vue, svelte, typst, ...
  -- installed or not) or without an `images` query (json, yaml, help, ...), so don't pay the
  -- treesitter work below
  local highlighter = vim.treesitter.highlighter.active[buf]
  if not (highlighter and has_images_query(highlighter.tree:lang())) then
    return false
  end

  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if cache.buf ~= buf or cache.tick ~= tick then
    cache.buf = buf
    cache.tick = tick
    cache.images = nil

    -- `find` parses asynchronously, so no image shows until it lands;
    -- refresh the statusline then if one turns out to cover the cursor
    Snacks.image.doc.find(buf, function(images)
      -- The buffer may have changed during the async gap; this result is for an older state
      if cache.buf ~= buf or cache.tick ~= tick then
        return
      end

      cache.images = images
      if
        vim.api.nvim_get_current_buf() == buf
        and image_at(images, vim.api.nvim_win_get_cursor(0))
      then
        UI.statusline.refresh()
      end
    end)
  end

  return cache.images ~= nil and image_at(cache.images, vim.api.nvim_win_get_cursor(0))
end

--- @return string
function M.get()
  return image_icon
end

M.color = 'green'

return M
