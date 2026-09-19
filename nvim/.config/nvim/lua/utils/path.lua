--- @class utils.path
local M = {}

--- Get the initial working directory path
--- Returns the directory passed as the single neovim argument, or the startup CWD.
--- @return string path The initial working directory path
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

--- Get a file path relative to the given root directory
--- Normalizes both paths before computing the relative path.
--- @param file string The absolute file path
--- @param root string The root directory path
--- @return string relative The relative path, or normalized absolute if not relative
function M.get_relative_path(file, root)
  local normalized_file = vim.fs.normalize(file)
  local normalized_root = vim.fs.normalize(root)
  local rel = vim.fs.relpath(normalized_root, normalized_file)
  return rel or normalized_file
end

return M
