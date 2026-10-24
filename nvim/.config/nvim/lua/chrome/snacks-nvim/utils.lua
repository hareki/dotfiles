local common = require('utils.common')

--- @class chrome.snacks.utils
local M = {}

--- @class chrome.snacks.utils.State
--- @field mapped table<integer, true> Buffers currently holding the temporary `q` mapping

--- @type chrome.snacks.utils.State
M.state = {
  mapped = {},
}

--- Map `q` to close the popup on its current buffer. A `win.keys` entry would outlive the popup
--- (Snacks never unmaps them, and zen shows the real buffer), shadowing macro recording there
--- @param win snacks.win
--- @return nil
local function map_close(win)
  local buf = win.buf
  -- Leave buffers that already spend `q` themselves (help, quickfix) alone
  -- rather than clobbering a mapping we would then have to restore
  if not buf or M.state.mapped[buf] or common.get_buf_keymap(buf, 'n', 'q') then
    return
  end

  M.state.mapped[buf] = true
  vim.keymap.set('n', 'q', function()
    win:close()
  end, { buffer = buf, nowait = true, desc = 'Close Zen Mode' })
end

--- Screen rect of the parent's whole frame, winbar row included, so the backdrop hides its
--- breadcrumb too (`getwininfo` counts only text rows in `height`, nothing for a dead window)
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

--- Toggle the popup over the current window, captured here since Snacks builds the backdrop only
--- once the popup has taken focus
--- @return nil
function M.toggle()
  local parent = vim.api.nvim_get_current_win()

  Snacks.zen({
    win = {
      -- Editor-relative, so the rect can start on the winbar row: win-relative row 0 is the first
      -- text row, and Snacks reads a negative row as an offset from the bottom edge
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
