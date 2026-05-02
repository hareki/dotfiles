---@class plugins.core.snacks.utils.image
local M = {}

---@class plugins.core.snacks.utils.image.State
---@field win integer
---@field buf integer
---@field placement snacks.image.Placement
---@field source_buf integer
---@field augroup integer

---@type plugins.core.snacks.utils.image.State?
local hover = nil

local function close()
  if not hover then
    return
  end

  local current = hover
  hover = nil

  pcall(vim.api.nvim_del_augroup_by_id, current.augroup)
  pcall(vim.keymap.del, 'n', '<Esc>', { buffer = current.source_buf })
  pcall(function()
    current.placement:close()
  end)
  pcall(vim.api.nvim_win_close, current.win, true)
  if vim.api.nvim_buf_is_valid(current.buf) then
    pcall(vim.api.nvim_buf_delete, current.buf, { force = true })
  end
end

---Build a hover-unique src path so the floating preview gets its own kitty
---graphics ID, decoupled from any inline placement of the same source. This
---prevents size juggling when the same image is rendered both inline and in
---the float, and ensures unsaved buffer edits (e.g. `.mmd` files) are picked
---up by re-hashing the live content.
---@param original_src string|nil  Resolved on-disk file (used when `content` is nil)
---@param ext string  File extension without leading dot
---@param content string|nil  Raw bytes to persist (e.g. live buffer text)
---@return string?
local function build_hover_src(original_src, ext, content)
  local cache = Snacks.image.config.cache
  vim.fn.mkdir(cache, 'p')

  local hash
  if content then
    hash = vim.fn.sha256(content):sub(1, 12)
  else
    if not original_src or vim.fn.filereadable(original_src) == 0 then
      return nil
    end
    local stat = (vim.uv or vim.loop).fs_stat(original_src)
    if not stat then
      return nil
    end
    -- Include nsec + size so a second edit within the same second doesn't
    -- collide with a stale cache entry.
    local key = table.concat({
      original_src,
      tostring(stat.mtime.sec),
      tostring(stat.mtime.nsec),
      tostring(stat.size),
    }, ':')
    hash = vim.fn.sha256(key):sub(1, 12)
  end

  local out = cache .. '/' .. hash .. '-hover.' .. ext

  if vim.fn.filereadable(out) == 1 then
    return out
  end

  if content then
    local fd = io.open(out, 'wb')
    if not fd then
      return nil
    end
    fd:write(content)
    fd:close()
  else
    local in_fd = io.open(original_src or '', 'rb')
    if not in_fd then
      return nil
    end
    local data = in_fd:read('*a')
    in_fd:close()
    local out_fd = io.open(out, 'wb')
    if not out_fd then
      return nil
    end
    out_fd:write(data)
    out_fd:close()
  end

  return out
end

---@param source_buf integer
---@param src string
local function open(source_buf, src)
  local ui = require('utils.ui')
  local lg = ui.popup_config('lg')

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = 'wipe'

  local augroup = vim.api.nvim_create_augroup('plugins.snacks.hover_image', { clear = true })

  local placement = Snacks.image.placement.new(scratch, src, {
    inline = false,
    -- Shift the image right by 1 cell so there's a left padding column;
    -- combined with `w = loc.width + 2` below, this gives 1 cell of padding
    -- on each side.
    pos = { 1, 1 },
    -- Reserve 2 cells (1 padding + 1 padding) so the image scales down to fit
    -- horizontally inside the padded window.
    max_width = lg.width - 2,
    -- Reserve 2 rows so the image scales down to fit, instead of the rendered
    -- image overflowing the window's bottom row.
    max_height = lg.height - 2,
    -- Defer window creation until snacks reports the rendered image's actual
    -- cell dims. Opening the window upfront would briefly show the full `lg`
    -- frame and then snap to the smaller image size — visible flash.
    on_update_pre = function(self)
      if not hover then
        return
      end
      if hover.win ~= -1 and vim.api.nvim_win_is_valid(hover.win) then
        return
      end

      -- Wipe any leftover extmarks (e.g. snacks's "<step> loading …" virt_text
      -- from `placement:progress()`, which it never clears once ready). The
      -- subsequent render() call will re-set image extmarks.
      vim.api.nvim_buf_clear_namespace(scratch, -1, 0, -1)

      local loc = self:state().loc
      local screen_w, screen_h = ui.screen_size()
      local w = loc.width + 2
      local h = loc.height + 2

      local win = vim.api.nvim_open_win(scratch, false, {
        relative = 'editor',
        width = w,
        height = h,
        col = math.floor((screen_w - w) / 2) - 1,
        row = math.floor((screen_h - h) / 2) - 1,
        border = 'rounded',
        style = 'minimal',
        focusable = false,
        noautocmd = true,
      })

      if Snacks.image.terminal.env().placeholders then
        vim.wo[win].winblend = 0
      end

      hover.win = win
    end,
  })

  hover = {
    win = -1, -- placeholder until on_update_pre opens the window
    buf = scratch,
    placement = placement,
    source_buf = source_buf,
    augroup = augroup,
  }

  vim.api.nvim_create_autocmd(
    { 'CursorMoved', 'CursorMovedI', 'BufLeave', 'ModeChanged', 'BufWipeout' },
    {
      group = augroup,
      buffer = source_buf,
      callback = close,
    }
  )

  vim.keymap.set('n', '<Esc>', close, {
    buffer = source_buf,
    desc = 'Close Hover Image',
  })
end

function M.hover_image()
  if hover then
    close()
    return
  end

  local source_buf = vim.api.nvim_get_current_buf()

  if vim.bo.filetype == 'mermaid' then
    local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    if content == '' then
      return
    end
    local src = build_hover_src(nil, 'mmd', content)
    if not src then
      return
    end
    open(source_buf, src)
    return
  end

  Snacks.image.doc.at_cursor(function(src)
    if not src then
      return
    end
    local ext = vim.fn.fnamemodify(src, ':e')
    if ext == '' then
      ext = 'png'
    end
    local hover_src = build_hover_src(src, ext, nil)
    if not hover_src then
      return
    end
    open(source_buf, hover_src)
  end)
end

return M
