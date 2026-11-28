--- Remembers the Claude session the agent panel ran, so that the panel of the next nvim in this
--- directory resumes it: auto-session saves it with the nvim session and hands it back on restore
--- (the auto-session fragment in the spec).
--- Entry point: Claude Code's SessionStart hook (claude-code's `nvim-session-start.sh`) calls
--- `report()` through `--remote-expr` on the nvim that started that Claude, so this path and that
--- name stay stable
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

--- The panel's terminal, while it has one
--- @return integer? buf
local function panel_buf()
  -- Without the plugin loaded there is no panel, and asking must not load it
  local terminal = package.loaded['claudecode.terminal']
  return terminal and terminal.get_active_terminal_bufnr()
end

--- The pid of the Claude the panel runs. claudecode.nvim starts it without a shell
--- @return integer?
local function panel_pid()
  local buf = panel_buf()
  if not buf then
    return nil
  end

  -- A job that has exited raises
  local ok, pid = pcall(vim.fn.jobpid, vim.bo[buf].channel)
  return ok and pid or nil
end

--- Record the session a Claude runs, when that Claude is the panel's. Every Claude started under
--- this nvim reports here, one in another terminal or one the panel's Claude ran itself
--- (`claude -p`) among them: its pid tells them apart. A `/clear` or a `/resume` reports again
--- @param id string
--- @param transcript string
--- @param pid string The reporting Claude's
function M.report(id, transcript, pid)
  local panel = panel_pid()
  if not panel or tonumber(pid) ~= panel then
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

--- Drop the session, ahead of an nvim session restore: one that holds no Claude session leaves the
--- panel none of the nvim session before it
function M.forget()
  state.session = nil
  state.restored = false
end

--- claudecode.nvim's `terminal_cmd`. The plugin asks on every open and toggle of the panel, though
--- only a start runs the answer. The first start after a restore takes up the restored session;
--- a Claude the user quits afterwards starts fresh, as it does without a restore
--- @return string
function M.command()
  if panel_buf() then
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
