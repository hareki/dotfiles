local panel = require('features.ai.claudecode-nvim.panel')

--- The panel's Claude session, saved with the nvim session so the next nvim here resumes it
--- Entry point: the SessionStart hook calls `report()` (`--remote-expr`): path and name stay stable
--- @class features.ai.claudecode-nvim.session
local M = {}

local CLAUDE = 'claude'

--- @class features.ai.claudecode-nvim.session.Session
--- @field id string
--- @field transcript string The conversation's file. Claude writes it with the first prompt, and resumes nothing without it

--- @class features.ai.claudecode-nvim.session.State
--- @field session? features.ai.claudecode-nvim.session.Session The last one the panel ran, here or in the nvim whose session was restored
--- @field restored boolean Whether `session` came with a restored nvim session and no panel has started since

--- @type features.ai.claudecode-nvim.session.State
local state = {
  session = nil,
  restored = false,
}

--- Record the session the panel's Claude runs; a `/clear` or a `/resume` reports again
--- @param id string
--- @param transcript string
--- @param pid string The reporting Claude's
function M.report(id, transcript, pid)
  if not panel.runs(pid) then
    return
  end

  state.session = { id = id, transcript = transcript }
  state.restored = false
end

--- auto-session's `save_extra_data`
--- @return string?
function M.save()
  return state.session and vim.json.encode(state.session) or nil
end

--- auto-session's `restore_extra_data`
--- @param _ string The nvim session's name
--- @param data string What `save()` returned
function M.restore(_, data)
  state.session = vim.json.decode(data)
  state.restored = true
end

--- Drop the session before an nvim session restore, which may hold none to replace it with
function M.forget()
  state.session = nil
  state.restored = false
end

--- claudecode.nvim's `terminal_cmd`, asked on every open and toggle though only a start runs it
--- Only the first start after a restore resumes the restored session
--- @return string
function M.command()
  if panel.buf() then
    return CLAUDE
  end

  local session = state.restored and state.session
  state.restored = false
  if not session then
    return CLAUDE
  end

  -- A session that never got a prompt
  if not vim.uv.fs_stat(session.transcript) then
    state.session = nil
    return CLAUDE
  end

  return string.format('%s --resume %s', CLAUDE, session.id)
end

return M
