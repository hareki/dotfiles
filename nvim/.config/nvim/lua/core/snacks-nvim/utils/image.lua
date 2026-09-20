local common = require('utils.common')

--- @class core.snacks.utils.image
local M = {}

--- @class core.snacks.utils.image.State
--- @field win integer
--- @field buf integer
--- @field placement snacks.image.Placement
--- @field augroup integer
--- @field release_keymaps fun()

--- @type core.snacks.utils.image.State?
local hover = nil

local function close()
  if not hover then
    return
  end

  local current = hover
  hover = nil

  pcall(vim.api.nvim_del_augroup_by_id, current.augroup)
  current.release_keymaps()
  pcall(function()
    current.placement:close()
  end)
  pcall(vim.api.nvim_win_close, current.win, true)
  if vim.api.nvim_buf_is_valid(current.buf) then
    pcall(vim.api.nvim_buf_delete, current.buf, { force = true })
  end
end

--- Build a hover-unique src path so the floating preview gets its own kitty
--- graphics ID, decoupled from any inline placement of the same source. This
--- prevents size juggling when the same image is rendered both inline and in
--- the float, and ensures unsaved buffer edits (e.g. `.mmd` files) are picked
--- up by re-hashing the live content.
--- @param original_src string | nil  Resolved on-disk file (used when `content` is nil)
--- @param ext string  File extension without leading dot
--- @param content string | nil  Raw bytes to persist (e.g. live buffer text)
--- @return string?
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
    local stat = vim.uv.fs_stat(original_src)
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
    --- @cast original_src string
    if not vim.uv.fs_copyfile(original_src, out) then
      return nil
    end
  end

  return out
end

--- @param source_buf integer
--- @param src string
local function open(source_buf, src)
  -- A second hover can arrive through the async at_cursor callback before the
  -- toggle guard sees the first; close it here, or replacing `hover` below
  -- would orphan its window, placement and <Esc> override
  if hover then
    close()
  end

  local lg = UI.layout.popup('lg')

  local scratch = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch].bufhidden = 'wipe'

  local augroup = vim.api.nvim_create_augroup('core.snacks.hover-image', { clear = true })

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
    -- frame and then snap to the smaller image size: a visible flash.
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
      local w = loc.width + 2
      local h = loc.height + 2
      local col, row = UI.layout.center(w, h)

      local win = vim.api.nvim_open_win(scratch, false, {
        relative = 'editor',
        width = w,
        height = h,
        col = col,
        row = row,
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
    augroup = augroup,
    release_keymaps = common.override_buf_keymaps(source_buf, {
      { 'n', '<Esc>', close, { desc = 'Close Hover Image' } },
    }),
  }

  vim.api.nvim_create_autocmd(
    { 'CursorMoved', 'CursorMovedI', 'BufLeave', 'ModeChanged', 'BufWipeout' },
    {
      group = augroup,
      buffer = source_buf,
      callback = close,
    }
  )
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

    -- Remote images: snacks downloads URLs itself, while the local-copy step
    -- below would fail filereadable() and silently drop the hover
    if src:find('^%w%w+://') then
      open(source_buf, src)
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
