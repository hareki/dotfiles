--- @class utils.path
local M = {}

--- Returns the directory passed as the single neovim argument, or the startup CWD.
--- @return string path
function M.get_initial_path()
  -- The cwd only catches up to a directory argument at VimEnter
  -- (lua/core/auto-session.lua), so resolve the argument itself.
  if vim.fn.argc() == 1 then
    local arg = vim.fn.argv(0) --[[@as string]]
    local stat = vim.uv.fs_stat(arg)
    if stat and stat.type == 'directory' then
      return vim.fs.normalize(vim.fn.fnamemodify(arg, ':p'))
    end
  end
  return vim.uv.cwd() or vim.fn.getcwd()
end

return M
