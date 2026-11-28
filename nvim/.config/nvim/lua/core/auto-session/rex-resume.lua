--- Reports a bare `nvim` to the Rex pane through the Program Resume Protocol (OSC 7577), so a Rex
--- server restart starts nvim again in its directory and auto-session restores the session there.
--- Rex trusts the command through the `nvim` rule in the Rex config (`features/nvim-resume.lua`)
--- @class core.auto-session.rex-resume
local M = {}

local state = {
  --- The pane's token, read once: the environment no longer holds it
  --- @type string?
  token = nil,
  --- Whether a bare `nvim` in the cwd restores this instance: auto-session restores only a
  --- launch without file arguments or stdin, and a session loaded later counts too
  active = false,
}

--- Tell the pane how to start this nvim again
--- @return nil
local function report()
  if not state.active then
    return
  end

  -- This process is nvim's server, and the pane runs its parent, the TUI
  local body = string.format(
    'pid=%d:time=%d:argv=%s:cwd=%s',
    vim.uv.os_getppid(),
    os.time(),
    vim.base64.encode('nvim'),
    vim.base64.encode(vim.fn.getcwd(-1, -1))
  )
  local mac = vim.fn.sha256(body .. ':' .. state.token)

  -- Through the TUI's own output, so the sequence never lands inside one the TUI is writing
  vim.api.nvim_ui_send(string.format('\27]7577;%s:mac=%s\27\\', body, mac))
end

--- Start reporting, when Rex runs this nvim. Call it before nvim reads its files or stdin
--- @return nil
function M.setup()
  state.token = vim.env.OSC7577_TOKEN
  if not state.token then
    return
  end

  -- A program nvim starts must not report in its place, nor resume instead of it. The server a
  -- `:restart` starts is one of them: it reports nothing, and the pane keeps this one's last report
  vim.env.OSC7577_TOKEN = nil

  local argc = vim.fn.argc()
  state.active = argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1)

  local group = vim.api.nvim_create_augroup('core.auto-session.rex-resume', { clear = true })

  vim.api.nvim_create_autocmd('StdinReadPre', {
    group = group,
    once = true,
    callback = function()
      state.active = false
    end,
  })

  vim.api.nvim_create_autocmd('SessionLoadPost', {
    group = group,
    callback = function()
      state.active = true
      report()
    end,
  })

  -- UIEnter for the first report, VimResume to take the pane back from a job run meanwhile
  vim.api.nvim_create_autocmd({ 'UIEnter', 'DirChanged', 'VimResume' }, {
    group = group,
    callback = report,
  })
end

return M
