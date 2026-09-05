--- @class core.snacks.utils.lazygit
local M = {}

--- @class core.snacks.utils.lazygit.State
--- @field win snacks.win? The single Lazygit terminal window
--- @field last_file string? Most recently focused normal-file path
--- @field last_win integer? Most recently focused non-floating window showing a normal buffer

--- @type core.snacks.utils.lazygit.State
M.state = {
  win = nil,
  last_file = nil,
  last_win = nil,
}

--- Path of the current buffer when it's a real, on-disk file; otherwise the last tracked file.
--- @return string?
local function target_file()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype == '' and name ~= '' then
    return name
  end
  return M.state.last_file
end

--- Register the autocmd that tracks the most recently focused normal buffer and the non-floating
--- window showing it, so `toggle` can fall back to the file when invoked from a non-file buffer
--- (terminal, plugin UI, unnamed) and `prepare_remote_edit` can land in a real editing window.
function M.setup()
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    group = vim.api.nvim_create_augroup('core.snacks.lazygit-last-focus', { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].buftype ~= '' then
        return
      end

      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= '' then
        M.state.last_file = name
      end

      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_config(win).relative == '' then
        M.state.last_win = win
      end
    end,
  })
end

--- Toggle the single Lazygit instance, preselecting the captured file on first launch.
--- `Snacks.terminal` keys instances on the full command (including `--file <path>`), so a
--- varying path would spawn a new terminal each time. To keep one instance, we hold the window
--- returned on creation and toggle it directly afterwards; `--file` only matters at startup.
function M.toggle()
  local state = M.state
  if state.win and state.win:buf_valid() then
    state.win:toggle()
    return
  end

  local file = target_file()
  state.win = Snacks.lazygit(file and { args = { '--file', file } } or nil)
end

--- Hide every visible Snacks terminal (Lazygit, floating terminal, coding agent) and refocus the
--- last editing window, so a file handed over by `nvim --server $NVIM --remote` lands there.
--- Nvim can't pick the window itself: closing a float nulls `prevwin`, so unwinding a stack of
--- them falls back to the top-left split.
function M.prepare_remote_edit()
  -- Snapshot before hiding: nvim's fallback landing fires WinEnter and would overwrite it
  local win = M.state.last_win

  for _, terminal in ipairs(Snacks.terminal.list()) do
    if terminal:valid() then
      terminal:hide()
    end
  end

  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

return M
