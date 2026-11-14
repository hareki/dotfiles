--- Entry point: Claude Code's Stop hook (`claude-code/.claude/hooks/nvim-when-done.sh` in the
--- dotfiles) calls `mark()` through `--remote-expr` on the nvim whose terminal runs that Claude,
--- so this path and that name stay stable
--- @class features.ai.claudecode-nvim.done
local M = {}

--- @class features.ai.claudecode-nvim.done.State
--- @field unseen boolean Claude finished, and no look since has found its panel showing

--- @type features.ai.claudecode-nvim.done.State
local state = {
  unseen = false,
}

--- Whether the agent panel shows in the current tab; toggled off, its float stays open but hidden
--- @return boolean
local function panel_visible()
  -- Without the plugin loaded there is no panel, and asking must not load it
  local terminal = package.loaded['claudecode.terminal']
  local buf = terminal and terminal.get_active_terminal_bufnr()
  local win = buf and vim.fn.bufwinid(buf) or -1
  return win ~= -1 and not vim.api.nvim_win_get_config(win).hide
end

--- Record that Claude is done; `unseen()` tells whether its panel shows that already
function M.mark()
  state.unseen = true
  UI.statusline.refresh()
end

--- Whether Claude finished out of sight and the panel hasn't shown since. The statusline asks on
--- every refresh, and the first one that finds the panel showing ends it
--- @return boolean
function M.unseen()
  if state.unseen and panel_visible() then
    state.unseen = false
  end
  return state.unseen
end

return M
