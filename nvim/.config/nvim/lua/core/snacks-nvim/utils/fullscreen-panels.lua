--- Keeps full-screen Snacks terminals (Lazygit, the coding agent) from stacking: toggling one on
--- replaces the one that's up, and toggling it off lands back on the code. Panels are detected
--- by geometry (any floating Snacks terminal covering the `full` popup preset), not registered.
--- @class core.snacks.utils.fullscreen-panels
local M = {}

--- Whether `terminal` is on screen as a full-screen panel. `valid()` alone isn't enough: the
--- coding agent hides its float with `nvim_win_set_config({ hide = true })` instead of closing
--- it, which keeps the window valid.
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
