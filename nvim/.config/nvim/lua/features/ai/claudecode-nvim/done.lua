--- Entry point: Claude Code's Stop hook (`claude-code/.claude/hooks/nvim-when-done.sh` in the
--- dotfiles) calls `mark()` through `--remote-expr` on the nvim whose terminal runs that Claude,
--- so this path and that name stay stable
--- @class features.ai.claudecode-nvim.done
local M = {}

--- @class features.ai.claudecode-nvim.done.State
--- @field unseen boolean Claude finished with its panel out of sight, and the panel hasn't shown since

--- @type features.ai.claudecode-nvim.done.State
local state = {
  unseen = false,
}

local GROUP = 'features.ai.claudecode-nvim.done.see-on-show'

--- Whether the agent panel shows in the current tab; toggled off, its float stays open but hidden
--- @return boolean
local function panel_visible()
  -- Without the plugin loaded there is no panel, and asking must not load it
  local terminal = package.loaded['claudecode.terminal']
  local buf = terminal and terminal.get_active_terminal_bufnr()
  if not buf then
    return false
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf and not vim.api.nvim_win_get_config(win).hide then
      return true
    end
  end
  return false
end

local function see_if_visible()
  if not (state.unseen and panel_visible()) then
    return
  end

  state.unseen = false
  vim.api.nvim_del_augroup_by_name(GROUP)
  UI.statusline.refresh()
end

--- Record that Claude is done, unless its panel shows that already
function M.mark()
  if state.unseen or panel_visible() then
    return
  end

  state.unseen = true
  UI.statusline.refresh()

  -- Every way this config shows the panel focuses it
  vim.api.nvim_create_autocmd('WinEnter', {
    group = vim.api.nvim_create_augroup(GROUP, { clear = true }),
    callback = function()
      -- A tick later: claudecode.nvim tracks a new panel only after its window is entered
      vim.schedule(see_if_visible)
    end,
  })
end

--- Whether Claude finished out of sight and the panel hasn't shown since
--- @return boolean
function M.unseen()
  return state.unseen
end

return M
