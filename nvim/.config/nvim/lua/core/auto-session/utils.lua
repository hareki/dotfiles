--- Entry point: the `tsave` zsh function calls `unsaved()` and `quit()` through `--remote-expr`,
--- so this module's path and those names must stay stable: with a broken one, tsave quits no nvim
--- and leaves tmux running
--- @class core.auto-session.utils
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

--- Publishes this nvim's RPC address on its tmux pane as `@nvim-server`, where the `tsave` zsh
--- function finds the nvims to quit through their normal exit (and auto-session's save) before
--- it kills the server
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

--- Quits once the RPC reply is out, through the normal exit path, so VimLeavePre runs
--- auto-session's save. The `!` only ends terminal jobs, since `tsave` has checked `unsaved()`
--- @return string
function M.quit()
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
