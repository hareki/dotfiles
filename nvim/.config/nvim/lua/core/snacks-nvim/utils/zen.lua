--- @class core.snacks.utils.zen
local M = {}

--- @class core.snacks.utils.zen.State
--- @field mapped table<integer, true> Buffers currently holding the temporary `q` mapping
--- @field parent integer? Window the popup was opened over

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

--- Zen mirrors its buffer into the parent window, which wipes that window's
--- local `winbar`, and the non-nested autocmd it does that from keeps dropbar
--- from re-attaching itself. Asking dropbar rather than replaying the old
--- string lets it re-decide, so a help or terminal buffer stays bare.
--- @return nil
local function restore_winbar()
  local parent = M.state.parent
  if not parent then
    return
  end

  -- Snacks mirrors the buffer from a later handler on the same event, so the
  -- swap has not landed yet; re-attach once the whole chain has run
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(parent) then
      return
    end

    -- dropbar's enable predicate short-circuits on a window that already has a
    -- winbar, so this is a no-op unless the swap really did clear it
    local bar = require('dropbar.utils.bar')
    bar.attach(vim.api.nvim_win_get_buf(parent), parent)
  end)
end

--- @param win snacks.win
--- @return nil
function M.on_open(win)
  map_close(win)

  -- The zen style sets fixbuf = false, so jumping to a definition or opening
  -- another file swaps the popup's buffer; each one needs its own mapping
  win:on('BufWinEnter', function()
    map_close(win)
    restore_winbar()
  end)
end

--- Open the popup over the current window, or close it when it is already up.
--- Snacks builds the backdrop only once the popup has taken focus, so the
--- window it has to cover can only be captured here, before that happens.
--- @return nil
function M.toggle()
  local parent = vim.api.nvim_get_current_win()
  M.state.parent = parent

  Snacks.zen({
    win = {
      backdrop = {
        win = {
          relative = 'win',
          win = parent,
          row = 0,
          col = 0,
          width = 0,
          -- Rows the backdrop spans to cover the parent's text. nvim counts
          -- the winbar row in a window's height, so spanning the full height
          -- would spill onto the statusline; winheight() reports the text area
          -- alone (and -1 for a dead window)
          height = function()
            return math.max(vim.fn.winheight(parent), 1)
          end,
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
  M.state.parent = nil
end

return M
