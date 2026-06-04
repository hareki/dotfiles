--- @class plugins.chrome.lualine.components.snacks_image
local M = {}

--- @class plugins.chrome.lualine.components.snacks_image.Cache
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
--- Mirrors the branching in `plugins.core.snacks.utils.image.hover_image`.
--- @return boolean
function M.cond()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  if ft == 'mermaid' then
    return mermaid_has_content(buf)
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
  -- Reset before the (often-synchronous) callback so a stale `true` is never
  -- displayed after the cursor leaves an image.
  cache.has_image = false

  Snacks.image.doc.at_cursor(function(src)
    cache.has_image = src ~= nil
  end)

  return cache.has_image
end

--- @return string
function M.get()
  return Icons.editor.image .. ' '
end

return M
