--- @class core.snacks.utils.lazygit
local M = {}

--- @class core.snacks.utils.lazygit.State
--- @field win snacks.win? The single Lazygit terminal window
--- @field last_file string? Most recently focused normal-file path

--- @type core.snacks.utils.lazygit.State
M.state = {
  win = nil,
  last_file = nil,
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

--- Register the autocmd that tracks the most recently focused normal-file buffer, so `toggle`
--- can fall back to it when invoked from a non-file buffer (terminal, plugin UI, unnamed).
function M.setup()
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('core.snacks.lazygit-last-file', { clear = true }),
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if vim.bo[args.buf].buftype == '' and name ~= '' then
        M.state.last_file = name
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

return M
