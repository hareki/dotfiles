--- @class utils.project-config.Config
--- @field linter 'eslint' | 'oxlint'
--- @field formatter 'prettier' | 'oxfmt'

--- @class utils.project-config
local M = {}

--- @type utils.project-config.Config
local defaults = { linter = 'eslint', formatter = 'prettier' }

--- Read and parse .neovimrc.json from the initial cwd, falling back to defaults.
--- @return utils.project-config.Config
function M.get()
  local path_utils = require('utils.path')
  local root = path_utils.get_initial_path()
  local file = vim.fs.joinpath(root, '.neovimrc.json')

  local stat = vim.uv.fs_stat(file)
  if not stat or stat.type ~= 'file' then
    return defaults
  end

  local ok_read, lines = pcall(vim.fn.readfile, file)
  if not ok_read or type(lines) ~= 'table' then
    Notifier.warn('Failed to read .neovimrc.json', { title = 'Project Config' })
    return defaults
  end

  local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok_decode or type(decoded) ~= 'table' then
    Notifier.warn('Failed to parse .neovimrc.json', { title = 'Project Config' })
    return defaults
  end

  --- @type utils.project-config.Config
  local cfg = { linter = defaults.linter, formatter = defaults.formatter }
  if decoded.linter == 'oxlint' or decoded.linter == 'eslint' then
    cfg.linter = decoded.linter
  end

  if decoded.formatter == 'oxfmt' or decoded.formatter == 'prettier' then
    cfg.formatter = decoded.formatter
  end

  return cfg
end

return M
