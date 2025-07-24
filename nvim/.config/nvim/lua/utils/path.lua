---@class utils.path
local M = {}

M.get_initial_path = function()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(tostring(first_arg), ':p')

  return initial_path
end

--- Get the file path relative to the given root.
--- @return string
function M.get_relative_path(file, root)
  -- Ensure both paths are absolute
  local absolute_file = vim.fn.fnamemodify(file, ':p')
  local absolute_root = vim.fn.fnamemodify(root, ':p')

  -- Normalize paths by removing trailing slashes
  if absolute_root:sub(-1) == '/' then
    absolute_root = absolute_root:sub(1, -2)
  end
  if absolute_file:sub(-1) == '/' then
    absolute_file = absolute_file:sub(1, -2)
  end

  -- Check if the file path starts with the root path
  if absolute_file:sub(1, #absolute_root) == absolute_root then
    -- Extract the relative path by removing the root path and the following slash
    local relative = absolute_file:sub(#absolute_root + 2)
    return relative
  else
    -- If the file is not inside the root, return the absolute path
    return absolute_file
  end
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
  local path = opts.path or vim.fn.expand('%:p:h')
  for dir in string.gmatch(path, '[^/]+') do
    if dir == dir_name then
      return true
    end
  end
  return false
end

return M
