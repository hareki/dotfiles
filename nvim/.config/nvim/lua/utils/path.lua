---@class utils.path
local M = {}

---@return string
function M.get_initial_path()
  -- We always set the cwd to match what's passed in neovim args if it's a directory in
  -- plugins/editor/auto-session.lua
  return vim.uv.cwd()
end

--- Get the file path relative to the given root.
---@param file string The file path
---@param root string The root path
---@return string
function M.get_relative_path(file, root)
  local normalized_file = vim.fs.normalize(file)
  local normalized_root = vim.fs.normalize(root)
  local rel = vim.fs.relpath(normalized_root, normalized_file)
  return rel or normalized_file
end

--- @class util.common.HasDirOptions
--- @field dir_name string     The directory name to search for (required).
--- @field path? string        The file system path to search (optional).
---
--- Checks whether a directory with the specified name exists in the given path components.
--- @param opts util.common.HasDirOptions  A table containing the options.
--- @return boolean            `true` if the directory is found in the path components, otherwise `false`.
function M.has_dir(opts)
  local dir_name = opts.dir_name
  local path = opts.path
  if not path or path == '' then
    path = vim.api.nvim_buf_get_name(0)
    if path ~= '' then
      path = vim.fs.dirname(path)
    end
    if not path or path == '' then
      path = vim.uv.cwd() or ''
    end
  end
  for dir in string.gmatch(path, '[^/]+') do
    if dir == dir_name then
      return true
    end
  end
  return false
end

return M
