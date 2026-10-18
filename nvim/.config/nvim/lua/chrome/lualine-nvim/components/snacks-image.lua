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
  if vim.api.nvim_buf_line_count(buf) > 1 then
    return true
  end
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  return first ~= nil and first ~= ''
end

--- Returns true when `gi` would render an image at the current cursor position.
--- Mirrors the branching in `features.preview.snacks.utils.hover_image`.
--- @return boolean
function M.cond()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  if ft == 'mermaid' then
    return mermaid_has_content(buf)
  end

  -- `gi` is a normal-mode key, while every insert/replace keystroke bumps the changedtick and
  -- would rerun the whole-buffer find() below (~2ms in an 850-line TSX file, ~6ms in a
  -- 1.6k-line README)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == 'i' or mode == 'R' then
    return false
  end

  -- Skip buffers whose language has no snacks `images` query (json, yaml, help, ...):
  -- nothing can match there, so don't pay the treesitter work below.
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang or not has_images_query(lang) then
    return false
  end

  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if cache.buf ~= buf or cache.tick ~= tick then
    cache.buf = buf
    cache.tick = tick
    cache.images = nil

    -- `find` parses asynchronously on nvim 0.11.4+, so no image shows until it lands;
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
