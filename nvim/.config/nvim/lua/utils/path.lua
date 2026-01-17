---@class utils.path
local M = {}

---Get the initial working directory path
---Returns the CWD set at startup (matches directory passed in neovim args).
---@return string path The initial working directory path
function M.get_initial_path()
  -- We always set the cwd to match what's passed in neovim args if it's a directory.
  -- See plugins/editor/auto-session.lua
  return vim.uv.cwd() or vim.fn.getcwd()
end

---Get a file path relative to the given root directory
---Normalizes both paths before computing the relative path.
---@param file string The absolute file path
---@param root string The root directory path
---@return string relative The relative path, or normalized absolute if not relative
function M.get_relative_path(file, root)
  local normalized_file = vim.fs.normalize(file)
  local normalized_root = vim.fs.normalize(root)
  local rel = vim.fs.relpath(normalized_root, normalized_file)
  return rel or normalized_file
end

---@class utils.path.HasDirOptions
---@field dir_name string     The directory name to search for (required).
---@field path? string        The file system path to search (optional).

---Check if a directory name exists in the given path components
---Useful for detecting if we're inside a specific project type (e.g., 'node_modules').
---@param opts utils.path.HasDirOptions Options with dir_name (required) and path (optional)
---@return boolean found True if the directory name is found in the path
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
