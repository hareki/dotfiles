--- The agent panel: its terminal (claudecode.nvim's), whether it shows, and which Claude is its own
--- @class features.ai.claudecode-nvim.panel
local M = {}

--- The panel's terminal, while it has one
--- @return integer? buf
function M.buf()
  -- Without the plugin loaded there is no panel, and asking must not load it
  local terminal = package.loaded['claudecode.terminal']
  return terminal and terminal.get_active_terminal_bufnr()
end

--- Whether the panel shows in the current tab; toggled off, its float stays open but hidden
--- @return boolean
function M.visible()
  local buf = M.buf()
  local win = buf and vim.fn.bufwinid(buf) or -1
  return win ~= -1 and not vim.api.nvim_win_get_config(win).hide
end

--- Whether the Claude of `pid` is the panel's job: claudecode.nvim starts it without a shell
--- Every Claude under this nvim reports here, one in another terminal or a `claude -p` among them
--- @param pid string As a hook passes its `$CLAUDE_PID`
--- @return boolean
function M.runs(pid)
  local buf = M.buf()
  if not buf then
    return false
  end

  -- A job that has exited raises
  local ok, panel_pid = pcall(vim.fn.jobpid, vim.bo[buf].channel)
  return ok and tonumber(pid) == panel_pid
end

return M
