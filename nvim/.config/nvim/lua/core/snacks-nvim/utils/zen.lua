--- @class core.snacks.utils.zen
local M = {}

--- @class core.snacks.utils.zen.State
--- @field mapped table<integer, true> Buffers currently holding the temporary `q` mapping

--- @type core.snacks.utils.zen.State
M.state = {
  mapped = {},
}

--- @param buf integer
--- @return boolean
local function has_own_q(buf)
  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(buf, 'n')) do
    if keymap.lhs == 'q' then
      return true
    end
  end

  return false
end

--- Map `q` to close the popup on the buffer it currently shows. Snacks applies
--- its own `win.keys` with `buffer = win.buf` and never unmaps them, and the zen
--- window displays the real buffer, so a `keys = { q = 'close' }` entry would
--- outlive the popup and shadow macro recording on that buffer.
--- @param win snacks.win
--- @return nil
local function map_close(win)
  local buf = win.buf
  -- Leave buffers that already spend `q` themselves (help, quickfix) alone
  -- rather than clobbering a mapping we would then have to restore
  if not buf or M.state.mapped[buf] or has_own_q(buf) then
    return
  end

  M.state.mapped[buf] = true
  vim.keymap.set('n', 'q', function()
    win:close()
  end, { buffer = buf, nowait = true, desc = 'Close Zen Mode' })
end

--- Screen rectangle of the parent's whole frame, winbar row included, so the
--- backdrop hides the parent's breadcrumb along with its text. `getwininfo`
--- counts text rows only in `height` and returns nothing for a dead window
--- @param parent integer
--- @return { row: integer, col: integer, height: integer, width: integer }
local function parent_rect(parent)
  local info = vim.fn.getwininfo(parent)[1]
  if not info then
    return { row = 0, col = 0, height = 1, width = 1 }
  end

  return {
    row = info.winrow - 1,
    col = info.wincol - 1,
    height = info.height + info.winbar,
    width = info.width,
  }
end

--- @param parent integer
--- @param key 'row' | 'col' | 'height' | 'width'
--- @return fun(): integer
local function rect_field(parent, key)
  return function()
    return parent_rect(parent)[key]
  end
end

--- @param win snacks.win
--- @return nil
function M.on_open(win)
  map_close(win)

  -- The zen style sets fixbuf = false, so jumping to a definition or opening
  -- another file swaps the popup's buffer; each one needs its own mapping
  win:on('BufWinEnter', function()
    map_close(win)
  end)
end

--- Open the popup over the current window, or close it when it is already up.
--- Snacks builds the backdrop only once the popup has taken focus, so the
--- window it has to cover can only be captured here, before that happens.
--- @return nil
function M.toggle()
  local parent = vim.api.nvim_get_current_win()

  Snacks.zen({
    win = {
      -- Editor-relative so the rect can start on the parent's winbar row: a
      -- win-relative row 0 is already the first text row, and Snacks reads a
      -- negative row as an offset from the bottom edge instead
      backdrop = {
        win = {
          row = rect_field(parent, 'row'),
          col = rect_field(parent, 'col'),
          height = rect_field(parent, 'height'),
          width = rect_field(parent, 'width'),
        },
      },
    },
  })
end

--- @return nil
function M.on_close()
  for buf in pairs(M.state.mapped) do
    pcall(vim.keymap.del, 'n', 'q', { buffer = buf })
  end

  M.state.mapped = {}
end

return M
