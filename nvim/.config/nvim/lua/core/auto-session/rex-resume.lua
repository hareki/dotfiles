--- Reports a bare `nvim` to the Rex pane through the Program Resume Protocol (OSC 7577), so a Rex
--- server restart starts nvim again in its directory and auto-session restores the session there.
--- Rex trusts the command through the `nvim` rule in the Rex config (`features/nvim-resume.lua`)
--- @class core.auto-session.rex-resume
local M = {}

local state = {
  --- The pane's token, read once: the environment no longer holds it
  --- @type string?
  token = nil,
}

--- Tell the pane how to start this nvim again, or to forget it when a bare `nvim` in the cwd would
--- not bring this instance back: auto-session restores there only what it saves. Does nothing
--- outside a Rex pane
--- @return nil
function M.report()
  if not state.token then
    return
  end

  local auto_session = require('auto-session')

  -- This process is nvim's server, and the pane runs its parent, the TUI
  local body = string.format('pid=%d:time=%d', vim.uv.os_getppid(), os.time())
  if auto_session.auto_save_conditions_met() then
    body = string.format(
      '%s:argv=%s:cwd=%s',
      body,
      vim.base64.encode('nvim'),
      vim.base64.encode(vim.fn.getcwd(-1, -1))
    )
  else
    body = body .. ':clear=1'
  end
  local mac = vim.fn.sha256(body .. ':' .. state.token)

  -- Through the TUI's own output, so the sequence never lands inside one the TUI is writing
  vim.api.nvim_ui_send(string.format('\27]7577;%s:mac=%s\27\\', body, mac))
end

--- Start reporting, when Rex runs this nvim. Call it before nvim starts any program
--- @return nil
function M.setup()
  state.token = vim.env.OSC7577_TOKEN
  if not state.token then
    return
  end

  -- A program nvim starts must not report in its place, nor resume instead of it. The server a
  -- `:restart` starts is one of them: it reports nothing, and the pane keeps this one's last report
  vim.env.OSC7577_TOKEN = nil

  -- UIEnter for the first report, VimResume to take the pane back from a job run meanwhile. A
  -- restored session reports through auto-session's `post_restore_cmds` (the spec)
  vim.api.nvim_create_autocmd({ 'UIEnter', 'DirChanged', 'VimResume' }, {
    group = vim.api.nvim_create_augroup('core.auto-session.rex-resume', { clear = true }),
    callback = M.report,
  })
end

return M
