--- @class chrome.lualine.components.snacks-image
local M = {}

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
  -- query.get is memoized by Neovim, so this is a table lookup after the first call.
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang or not vim.treesitter.query.get(lang, 'images') then
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
  return Conf.icons.editor.IMAGE .. ' '
end

return M
