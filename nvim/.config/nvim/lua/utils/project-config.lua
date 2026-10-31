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
  local file = vim.fs.joinpath(vim.fn.getcwd(), '.neovimrc.json')

  local stat = vim.uv.fs_stat(file)
  if not stat or stat.type ~= 'file' then
    return defaults
  end

  local ok_read, lines = pcall(vim.fn.readfile, file)
  if not ok_read then
    Notifier.warn('Failed to read .neovimrc.json', { title = 'Project Config' })
    return defaults
  end

  local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok_decode or type(decoded) ~= 'table' then
    Notifier.warn('Failed to parse .neovimrc.json', { title = 'Project Config' })
    return defaults
  end

  return {
    linter = decoded.linter == 'oxlint' and 'oxlint' or defaults.linter,
    formatter = decoded.formatter == 'oxfmt' and 'oxfmt' or defaults.formatter,
  }
end

return M
