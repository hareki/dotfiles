--- @class chrome.lualine.components.snacks-image
local M = {}

local image_icon = Conf.icons.editor.IMAGE .. ' '

-- query.get's GC-weak cache re-scans the runtimepath after a collection: pin the answer for redraws
--- @type table<string, boolean>
local lang_has_images_query = {}

--- @param lang string A language with a loaded parser
--- @return boolean
local function has_images_query(lang)
  local has = lang_has_images_query[lang]
  if has == nil then
    -- query.get throws on a query the installed grammar can't parse, breaking every redraw
    local ok, query = pcall(vim.treesitter.query.get, lang, 'images')
    has = ok and query ~= nil
    lang_has_images_query[lang] = has
  end
  return has
end

-- Images of one buffer state: cursor moves test against them, a buffer or text change requeries
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

  -- `gi` is normal-mode, and each insert keystroke would rerun the find() below (~2ms at 850 lines)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == 'i' or mode == 'R' then
    return false
  end

  -- Nothing can match without a parser or an `images` query, so skip the treesitter work below
  local highlighter = vim.treesitter.highlighter.active[buf]
  if not (highlighter and has_images_query(highlighter.tree:lang())) then
    return false
  end

  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if cache.buf ~= buf or cache.tick ~= tick then
    cache.buf = buf
    cache.tick = tick
    cache.images = nil

    -- `find` parses asynchronously, so refresh the statusline if an image ends up under the cursor
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
