local popup = require('utils.popup')

--- The image or mermaid diagram under the cursor, shown in a centered float until the cursor moves on
--- @class features.preview.snacks-nvim.hover-image
local M = {}

--- Closer of the open hover, from popup.link
--- @type fun()?
local active

--- A path unique to `key`, since Snacks caches images per path: placing an edited file by its own
--- path would keep showing the old pixels
--- @param key string Hashed into the file name
--- @param ext string File extension without leading dot
--- @return string
local function hover_path(key, ext)
  local cache = Snacks.image.config.cache
  vim.fn.mkdir(cache, 'p')

  return vim.fs.joinpath(cache, vim.fn.sha256(key):sub(1, 12) .. '-hover.' .. ext)
end

--- Hover copy of a mermaid buffer's text, keyed on it so unsaved edits are re-hashed
--- @param text string
--- @return string?
local function hover_src_from_text(text)
  local out = hover_path(text, 'mmd')
  if vim.fn.filereadable(out) == 1 then
    return out
  end

  local fd = io.open(out, 'wb')
  if fd then
    fd:write(text)
    fd:close()
    return out
  end
end

--- Hover copy of an on-disk image
--- @param src string
--- @return string?
local function hover_src_from_file(src)
  local stat = vim.uv.fs_stat(src)
  if not stat then
    return nil
  end

  -- Include nsec + size so a second edit within the same second can't hit a stale cache entry
  local key = table.concat({ src, stat.mtime.sec, stat.mtime.nsec, stat.size }, ':')
  local ext = vim.fs.ext(src)
  local out = hover_path(key, ext ~= '' and ext or 'png')

  if vim.fn.filereadable(out) == 1 or vim.uv.fs_copyfile(src, out) then
    return out
  end
end

--- @param src string? Nothing opens without one
local function open(src)
  if not src then
    return
  end

  -- A second hover can arrive via the async at_cursor callback before the toggle guard sees the
  -- first; close it, or its window and placement would be orphaned
  if active then
    active()
  end

  local lg = UI.layout.popup('lg')

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = 'wipe'

  -- Hidden until snacks reports the image's cell dims, or the full `lg` frame flashes; already at
  -- `lg` size, since the placement sizes the image within the windows showing its buffer
  local win = vim.api.nvim_open_win(scratch, false, {
    relative = 'editor',
    width = lg.width,
    height = lg.height,
    col = 0,
    row = 0,
    border = 'rounded',
    style = 'minimal',
    focusable = false,
    noautocmd = true,
    hide = true,
  })

  local placement = Snacks.image.placement.new(scratch, src, {
    inline = false,
    -- Shift the image 1 cell right; with `w = loc.width + 2` below, that pads 1 cell on each side
    pos = { 1, 1 },
    -- Reserve the 2 padding cells so the image scales down to fit the padded window
    max_width = lg.width - 2,
    -- Reserve 2 rows so the image scales down rather than overflowing the bottom row
    max_height = lg.height - 2,
    -- Show the window once snacks reports the image's cell dims
    on_update_pre = function(self)
      if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_win_get_config(win).hide then
        return
      end

      local loc = self:state().loc
      local w = loc.width + 2
      local h = loc.height + 2
      local col, row = UI.layout.center(w, h)

      vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        width = w,
        height = h,
        col = col,
        row = row,
        hide = false,
      })
    end,
  })

  active = popup.link(win, {
    name = 'Hover Image',
    keys = false,
    close_on = { cursor_moved = true, focus_left = true, mode_changed = true },
    on_close = function()
      active = nil
      pcall(placement.close, placement)
    end,
  })
end

--- Toggle the hover for the image or mermaid diagram at the cursor
--- @return nil
function M.toggle()
  if active then
    active()
    return
  end

  local source_buf = vim.api.nvim_get_current_buf()

  if vim.bo.filetype == 'mermaid' then
    local text = table.concat(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false), '\n')
    if text ~= '' then
      open(hover_src_from_text(text))
    end
    return
  end

  Snacks.image.doc.at_cursor(function(src)
    if src then
      -- Snacks downloads URLs itself; a local copy would silently drop the hover
      open(Snacks.image.convert.is_uri(src) and src or hover_src_from_file(src))
    end
  end)
end

return M
