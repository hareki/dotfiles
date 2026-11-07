--- Full-screen Snacks terminals (Lazygit, the coding agent): builds their window config, pinned
--- to Terminal mode, and keeps them from stacking, so closing one lands on the code (panels are
--- detected by geometry, covering the `full` preset)
--- @class core.snacks.utils
local M = {}

--- Pins a panel to Terminal mode: its app takes every key and click itself, so Normal mode there
--- only strands the cursor
--- @type snacks.win.Config
local terminal_mode = {
  keys = {
    -- Replaces Snacks' double <Esc> exit, which also swallows the second press (Claude's rewind,
    -- Lazygit's nested popups); a buffer-local <Esc> also keeps the global <Esc><Esc> map from
    -- holding every single press for 'timeoutlen'. With `expr`, Snacks sends an rhs that names no
    -- action as keys
    term_normal = { '<Esc>', '<Esc>', mode = 't', expr = true, desc = 'Send Escape' },
  },

  --- Clicks and scrolls the app can't take, like those on the border, still leave Terminal mode
  --- @param self snacks.win
  on_buf = function(self)
    -- `show()` recreates this group right before calling `on_buf`, so nothing piles up
    vim.api.nvim_create_autocmd('TermLeave', {
      group = self.augroup,
      buffer = self.buf,
      callback = function()
        -- Runs after the input that left: a click on another window has moved focus there by then
        vim.schedule(function()
          if
            vim.api.nvim_get_current_buf() == self.buf and vim.api.nvim_get_mode().mode == 'nt'
          then
            vim.cmd.startinsert()
          end
        end)
      end,
    })
  end,
}

--- Window config of a full-screen panel: the `full` preset `hide_others` detects panels by, pinned
--- to Terminal mode. A merge rather than a Snacks style, which would lose `on_buf` to the
--- claudecode.nvim fork's own `on_buf`
--- @param overrides snacks.win.Config|{} The panel's own options (title, position, backdrop)
--- @return snacks.win.Config
function M.win_config(overrides)
  return vim.tbl_extend('force', UI.layout.popup_fn('full'), terminal_mode, overrides)
end

--- Whether `terminal` is up as a full-screen panel; `valid()` alone misses the agent's hidden float
--- @param terminal snacks.win
--- @param full utils.ui.layout.WinConfig Resolved `full` preset to compare against
--- @return boolean
local function is_visible_panel(terminal, full)
  if not terminal:valid() then
    return false
  end

  local config = vim.api.nvim_win_get_config(terminal.win)
  if config.relative == '' or config.hide then
    return false
  end

  return config.width >= full.width and config.height >= full.height
end

--- Hide every visible full-screen panel except the one owning `buf`. Call it right before
--- toggling a panel: a no-op when that panel is already up, since nothing else can be.
--- @param buf? integer Buffer of the panel about to be toggled; nil when it doesn't exist yet
function M.hide_others(buf)
  local full = UI.layout.popup('full')
  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal.buf ~= buf and is_visible_panel(terminal, full) then
      terminal:hide()
    end
  end
end

return M
