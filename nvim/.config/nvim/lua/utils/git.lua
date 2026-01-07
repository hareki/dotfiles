---@alias utils.git.branch_formats 'id' | 'id_and_name' | 'id_and_author'

---@class utils.git
local M = {}

local branch_display_mode = 'id'

-- Task name truncation settings: show first TASK_NAME_START_LENGTH chars + '...' + last TASK_NAME_END_LENGTH chars
local TASK_NAME_START_LENGTH = 999
local TASK_NAME_END_LENGTH = 10
local max_task_name_length = TASK_NAME_START_LENGTH + TASK_NAME_END_LENGTH

-- A cache table to store the repository name and last known CWD
local repo_cache = {
  name = nil,
  last_cwd = nil,
  toplevel = nil,
}

local branch_format_cache = {} -- LRU cache for formatted branch names (max 100 entries to prevent unbounded growth)
local branch_format_cache_order = {} -- Track access order for LRU
local BRANCH_CACHE_MAX_SIZE = 100

---Sets the branch display format and refreshes the status line.
---@param format utils.git.branch_formats The name of the branch format to set.
function M.set_branch_name_format(format)
  branch_display_mode = format
  -- Clear both cache and order when format changes
  branch_format_cache = {}
  branch_format_cache_order = {}

  Notifier.info('Branch name format set to ' .. format)

  if require('plugins.ui.lualine.utils').have_status_line() then
    require('lualine').refresh({ place = { 'statusline' } })
  end
end

---Formats a given branch name according to the selected display mode.
---@param branch_name string The original branch name to be formatted.
---@return string The formatted branch name.
function M.format_branch_name(branch_name)
  -- Check cache first
  local cache_key = branch_display_mode .. ':' .. branch_name
  if branch_format_cache[cache_key] then
    -- Move to end of LRU order (most recently used)
    for i, key in ipairs(branch_format_cache_order) do
      if key == cache_key then
        table.remove(branch_format_cache_order, i)
        break
      end
    end
    table.insert(branch_format_cache_order, cache_key)
    return branch_format_cache[cache_key]
  end

  local prefix
  local remaining

  if branch_name:match('^CU%-%w+') then
    prefix, remaining = branch_name:match('^(CU%-%w+)_(.+)$')
  else
    remaining, prefix = branch_name:match('^(.*)_(CU%-%w+)$')
  end

  if not prefix or not remaining or remaining == '' then
    branch_format_cache[cache_key] = branch_name
    return branch_name
  end

  local task_name = remaining
  local author_name

  local possible_task, possible_author = remaining:match('^(.*)_(.+)$')
  if possible_task and possible_task ~= '' and possible_author and possible_author ~= '' then
    task_name = possible_task
    author_name = possible_author
  end

  local result
  if branch_display_mode == 'id' then
    result = prefix
  elseif branch_display_mode == 'id_and_name' then
    local formatted_task_name = task_name
    if #task_name > max_task_name_length then
      -- Show start and end parts of the task name with ellipsis
      formatted_task_name = task_name:sub(1, TASK_NAME_START_LENGTH)
        .. '...'
        .. task_name:sub(-TASK_NAME_END_LENGTH)
    end
    result = prefix .. '_' .. formatted_task_name
  elseif branch_display_mode == 'id_and_author' then
    if author_name then
      result = prefix .. '_' .. author_name
    else
      result = prefix
    end
  else
    result = ''
  end

  -- Evict least recently used if cache is full
  if #branch_format_cache_order >= BRANCH_CACHE_MAX_SIZE then
    local oldest_key = table.remove(branch_format_cache_order, 1)
    branch_format_cache[oldest_key] = nil
  end

  branch_format_cache[cache_key] = result
  table.insert(branch_format_cache_order, cache_key)
  return result
end

--- Executes a git command synchronously and returns its output.
---@param cmd string The git command to execute (without the 'git' prefix).
---@param cwd string|nil The directory in which to execute the command. Defaults to current directory if nil.
---@return string|nil The trimmed output of the command, or nil if an error occurs.
function M.exec_cmd(cmd, cwd)
  local args = vim.split(cmd, '%s+')
  local git_cmd = { 'git' }

  if cwd then
    vim.list_extend(git_cmd, { '-C', cwd })
  end

  vim.list_extend(git_cmd, args)

  local result = vim.system(git_cmd, { text = true }):wait()

  if result.code == 0 and result.stdout and result.stdout ~= '' then
    -- Trim whitespace and newlines
    local trimmed = result.stdout:gsub('%s+$', ''):gsub('^%s+', '')
    return trimmed
  end

  return nil
end

--- Retrieves the repository name from the remote origin URL.
---@return string|nil The repository name extracted from the remote URL, or nil if not found.
function M.get_repo_name_from_remote()
  local url = M.exec_cmd('config --get remote.origin.url')
  if not url or url == '' then
    return nil
  end

  -- Remove .git suffix if present
  url = url:gsub('%.git$', '')

  -- Extract the last path component (repo name)
  local repo_name = url:match('([^/]+)$')

  return repo_name
end

--- Determines whether a specified directory is a bare Git repository.
---@param path string The directory path to check.
---@return boolean True if the directory is a bare repository, false otherwise.
function M.is_bare_repo(path)
  if not path then
    return false
  end
  local result = M.exec_cmd('rev-parse --is-bare-repository', path)
  return result == 'true'
end

--- Extracts the repository name from a given file system path.
---@param path string The file system path from which to extract the repository name.
---@return string|nil The repository name (last component of the path), or nil if invalid.
function M.get_repo_name_from_path(path)
  return path:match('([^/\\]+)$')
end

--- Retrieves the repository name using multiple strategies and caches the result.
---@return string|nil The repository name determined by the implemented logic.
function M.get_repo_name()
  local current_cwd = vim.uv.cwd()

  if repo_cache.name and repo_cache.last_cwd == current_cwd then
    return repo_cache.name
  end

  -- Get toplevel to determine if we're in the same repo
  local toplevel = M.exec_cmd('rev-parse --show-toplevel')

  -- Check if we're still in the same repo (same toplevel) and cache is recent
  if repo_cache.name and repo_cache.toplevel == toplevel then
    return repo_cache.name
  end

  -- Update cache markers
  repo_cache.last_cwd = current_cwd
  repo_cache.toplevel = toplevel

  -- Step 1: Attempt to get the repository name from the remote URL
  local repo_name = M.get_repo_name_from_remote()
  if repo_name then
    repo_cache.name = repo_name
    return repo_name
  end

  -- Step 2: Determine if the parent of the top-level directory is a bare repository
  if toplevel and toplevel ~= '' then
    -- Extract the parent directory of the top-level directory
    local parent_dir = toplevel:match('(.+)/[^/\\]+$') or toplevel:match('(.+)\\[^\\]+$')
    if parent_dir and parent_dir ~= '' then
      if M.is_bare_repo(parent_dir) then
        -- Extract the repository name from the parent directory
        local parent_repo_name = M.get_repo_name_from_path(parent_dir)
        if parent_repo_name then
          repo_cache.name = parent_repo_name
          return parent_repo_name
        end
      end
    end

    -- If the parent directory is not a bare repository, extract from the top-level directory
    local toplevel_repo_name = M.get_repo_name_from_path(toplevel)
    if toplevel_repo_name then
      repo_cache.name = toplevel_repo_name
      return toplevel_repo_name
    end
  end

  -- Step 3: Fallback to using the current working directory's name
  local cwd_name = M.get_repo_name_from_path(current_cwd or '')
  repo_cache.name = cwd_name or 'Unknown'
  return repo_cache.name
end

---Get the commit hash of the last commit affecting the current line in the current buffer.
---@return string|nil The commit hash if found, or nil if not.
function M.get_current_line_commit()
  ---@type integer
  local line = vim.api.nvim_win_get_cursor(0)[1]

  ---@type string
  local file = vim.api.nvim_buf_get_name(0)

  ---@type string|nil
  local root = Snacks.git.get_root()
  if not root then
    Notifier.error('Not inside a Git repository')
    return nil
  end

  local relative_file = require('utils.path').get_relative_path(file, root)

  ---@type string[]
  local cmd = {
    'git',
    '-C',
    root,
    'log',
    '-n',
    '1',
    '-L',
    string.format('%d,%d:%s', line, line, relative_file),
  }

  local res = vim.system(cmd, { text = true }):wait()
  if not res or res.code ~= 0 then
    Notifier.error('Git command failed. Ensure the file is tracked and has sufficient history.')
    return nil
  end

  local output = vim.split((res.stdout or ''):gsub('\n$', ''), '\n')

  ---@type string|nil
  local current_commit = nil
  for _, out_line in ipairs(output) do
    current_commit = out_line:match('^commit%s+([0-9a-f]+)')
    if current_commit then
      break
    end
  end

  return current_commit
end

---Open Diffview to compare a commit with its previous state.
---@param commit? string The commit hash or reference to compare.
function M.diff_parent(commit)
  if not commit or commit == '' then
    -- No commit provided, show the current changes (both staged and unstaged) compared with the last commit
    vim.cmd.DiffviewOpen()
  else
    --- Open Diffview with the commit range using commit~1.
    vim.cmd.DiffviewOpen({ args = { string.format('%s~1..%s', commit, commit) } })
  end
end

return M
