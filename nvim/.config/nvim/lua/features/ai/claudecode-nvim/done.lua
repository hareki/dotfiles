local panel = require('features.ai.claudecode-nvim.panel')

--- Entry point: Claude Code's Stop hook (claude-code's `nvim-when-done.sh`) calls `mark()` through
--- `--remote-expr` on the nvim running that Claude, so this path and that name stay stable
--- @class features.ai.claudecode-nvim.done
local M = {}

--- @class features.ai.claudecode-nvim.done.State
--- @field unseen boolean The panel's Claude finished, and no look since has found the panel showing

--- @type features.ai.claudecode-nvim.done.State
local state = {
  unseen = false,
}

--- Record that the panel's Claude is done; `unseen()` checks whether the panel shows it already
--- @param pid string The reporting Claude's
function M.mark(pid)
  if not panel.runs(pid) then
    return
  end

  state.unseen = true
  UI.statusline.refresh()
end

--- Whether the panel's Claude finished out of sight and the panel hasn't shown since. The
--- statusline asks on every refresh, and the first one that finds the panel showing ends it
--- @return boolean
function M.unseen()
  if state.unseen and panel.visible() then
    state.unseen = false
  end
  return state.unseen
end

return M
