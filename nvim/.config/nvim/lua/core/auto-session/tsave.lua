--- Entry point: the `tsave` zsh function calls `unsaved()` and `quit()` through `--remote-expr`, so
--- path and names stay stable; zsh's `tests/tsave.zsh` runs it under --clean: no globals or modules
--- @class core.auto-session.tsave
local M = {}

--- Whether `pid` or one of its descendants is an nvim process
--- @param pid integer
--- @return boolean
local function runs_nvim(pid)
  local proc = vim.api.nvim_get_proc(pid)
  if proc and proc.name == 'nvim' then
    return true
  end

  for _, child in ipairs(vim.api.nvim_get_proc_children(pid)) do
    if runs_nvim(child) then
      return true
    end
  end
  return false
end

--- Publishes this nvim's RPC address on its tmux pane as `@nvim-server`, where `tsave` finds the
--- nvims to quit through their normal exit (and auto-session's save) before it kills the server
--- @return nil
function M.publish_tmux_server()
  local pane = vim.env.TMUX_PANE
  -- Nested nvims (:terminal, lazygit's editor) share the pane's env but aren't its own nvim
  if not pane or vim.env.NVIM or #vim.api.nvim_list_uis() == 0 then
    return
  end

  vim.system({ 'tmux', 'set-option', '-p', '-t', pane, '@nvim-server', vim.v.servername })
end

--- Lists what `tsave` must not throw away when it quits nvim: buffers `:qall` would refuse to
--- drop, and terminals running a nested nvim, which `qall!` would end along with its edits
--- @return string blockers One per line, empty when nvim can quit
function M.unsaved()
  local blockers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buftype = vim.bo[buf].buftype
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].modified and (buftype == '' or buftype == 'acwrite') then
      table.insert(
        blockers,
        name == '' and string.format('[No Name] (buf %d)', buf) or vim.fn.fnamemodify(name, ':~:.')
      )
    elseif buftype == 'terminal' then
      local job_pid = vim.b[buf].terminal_job_pid
      if job_pid and runs_nvim(job_pid) then
        table.insert(blockers, string.format('nested nvim in %s', name))
      end
    end
  end
  return table.concat(blockers, '\n')
end

--- Quits after the RPC reply, by the normal exit path so VimLeavePre saves the session. `!` only
--- ends terminal jobs, as `tsave` checked `unsaved()`; work gained since then keeps nvim running
--- @return string blockers What kept nvim running, empty when it quits
function M.quit()
  local blockers = M.unsaved()
  if blockers ~= '' then
    return blockers
  end

  vim.schedule(function()
    vim.cmd('qall!')
    -- Still running: an ExitPre handler closed the current window, which aborts a quit. Snacks
    -- closes its terminals there, so focus in one (tsave's own float terminal, Lazygit) lands here
    vim.cmd('qall!')
  end)
  -- A nil result would reach --remote-expr as vim.NIL
  return ''
end

return M
