---@alias utils.git.branch_formats 'id' | 'id_and_name' | 'id_and_author'

---@class utils.git
local M = {}

local branch_display_mode = 'id'

local task_name_start_length = 999
local task_name_end_length = 10
local max_task_name_length = task_name_start_length + task_name_end_length

-- A cache table to store the repository name and last known CWD
local repo_cache = {
  name = nil,
  last_cwd = nil,
}

--- Sets the branch display format and refreshes the status line.
--- @param format utils.git.branch_formats The name of the branch format to set.
function M.set_branch_name_format(format)
  branch_display_mode = format
  vim.notify('Branch name format set to ' .. format)
  require('lualine').refresh()
end

--- Formats a given branch name according to the selected display mode.
--- @param branch_name string The original branch name to be formatted.
--- @return string The formatted branch name.
function M.format_branch_name(branch_name)
  local is_clickup_format = branch_name:match('^CU%-%w+_.+_.+$')
  if not is_clickup_format then
    return branch_name
  end

  local prefix, task_name, author_name = branch_name:match('^(CU%-%w+)_([^_]+)_(.+)$')

  if branch_display_mode == 'id' then
    return prefix
  elseif branch_display_mode == 'id_and_name' then
    local formatted_task_name
    if #task_name > max_task_name_length then
      -- Show start and end parts of the task name with ellipsis
      formatted_task_name = task_name:sub(1, task_name_start_length)
        .. '...'
        .. task_name:sub(-task_name_end_length)
    else
      formatted_task_name = task_name
    end
    return prefix .. '_' .. formatted_task_name
  elseif branch_display_mode == 'id_and_author' then
    return prefix .. '_' .. author_name
  end

  return ''
end

--- Executes a shell command, optionally in a specified directory, and returns its output.
--- @param cmd string The shell command to execute.
--- @param cwd string|nil The directory in which to execute the command. Defaults to current directory if nil.
--- @return string|nil The trimmed output of the command, or nil if an error occurs.
function M.exec_cmd(cmd, cwd)
  local full_cmd = cmd
  if cwd then
    -- Use 'git -C <cwd> <CMD>' to execute the command in the specified directory
    full_cmd = 'git -C "' .. cwd .. '" ' .. cmd
  end
  -- Open a pipe to execute the command, redirecting stderr to /dev/null
  local handle = io.popen(full_cmd .. ' 2>/dev/null')
  if handle then
    local result = handle:read('*a')
    handle:close()
    if result and result ~= '' then
      -- Trim whitespace and newlines
      return result:gsub('%s+', '')
    end
  end
  return nil
end

--- Retrieves the repository name from the remote origin URL.
--- @return string|nil The repository name extracted from the remote URL, or nil if not found.
function M.get_repo_name_from_remote()
  -- Execute the basename command to strip the .git suffix
  -- Command: basename -s .git $(git config --get remote.origin.url)
  local cmd = 'basename -s .git $(git config --get remote.origin.url)'
  local repo_name = M.exec_cmd(cmd)
  if repo_name and repo_name ~= '' then
    return repo_name
  end
  return nil
end

--- Determines whether a specified directory is a bare Git repository.
--- @param path string The directory path to check.
--- @return boolean True if the directory is a bare repository, false otherwise.
function M.is_bare_repo(path)
  if not path or path == '' then
    return false
  end
  local result = M.exec_cmd('rev-parse --is-bare-repository', path)
  return result == 'true'
end

--- Extracts the repository name from a given file system path.
--- @param path string The file system path from which to extract the repository name.
--- @return string|nil The repository name (last component of the path), or nil if invalid.
function M.get_repo_name_from_path(path)
  return path:match('([^/\\]+)$')
end

--- Retrieves the repository name using multiple strategies and caches the result.
--- @return string|nil The repository name determined by the implemented logic.
function M.get_repo_name()
  local current_cwd = vim.fn.getcwd()

  -- Check if the CWD has changed since the last cache
  if repo_cache.name and repo_cache.last_cwd == current_cwd then
    return repo_cache.name
  end

  -- Update the last known CWD
  repo_cache.last_cwd = current_cwd

  -- Step 1: Attempt to get the repository name from the remote URL
  local repo_name = M.get_repo_name_from_remote()
  if repo_name then
    repo_cache.name = repo_name
    return repo_name
  end

  -- Step 2: Determine if the parent of the top-level directory is a bare repository
  local toplevel = M.exec_cmd('rev-parse --show-toplevel')
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
  local cwd_name = M.get_repo_name_from_path(current_cwd)
  repo_cache.name = cwd_name or 'Unknown'
  return repo_cache.name
end

--- Get the commit hash of the last commit affecting the current line in the current buffer.
---
--- @return string|nil The commit hash if found, or nil if not.
function M.get_current_line_commit()
  --- Get the current line number.
  --- @type integer
  local line = vim.api.nvim_win_get_cursor(0)[1]

  --- Get the current file path.
  --- @type string
  local file = vim.api.nvim_buf_get_name(0)

  --- Get Git root directory.
  --- @type string|nil
  local root = Snacks.git.get_root()
  if not root then
    vim.notify('Not inside a Git repository', vim.log.levels.ERROR)
    return nil
  end

  local relative_file = require('utils.path').get_relative_path(file, root)

  --- Construct the Git log command to get the last commit for the current line.
  --- @type string[]
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

  --- Execute the Git command and capture the output.
  --- @type string[]
  local output = vim.fn.systemlist(cmd)

  -- Check for Git command errors.
  if vim.v.shell_error ~= 0 then
    vim.notify(
      'Git command failed. Ensure the file is tracked and has sufficient history.',
      vim.log.levels.ERROR
    )
    return nil
  end

  --- Extract the current commit hash from the Git command output.
  --- @type string|nil
  local current_commit = nil
  for _, out_line in ipairs(output) do
    current_commit = out_line:match('^commit%s+([0-9a-f]+)')
    if current_commit then
      break
    end
  end

  return current_commit
end

--- Open Diffview to compare a commit with its previous state.
---
--- @param commit? string The commit hash or reference to compare.
function M.diff_parent(commit)
  if not commit or commit == '' then
    -- No commit provided, show the current changes (both staged and unstaged) compared with the last commit
    vim.cmd('DiffviewOpen')
  else
    --- Open Diffview with the commit range using commit~1.
    vim.cmd(string.format('DiffviewOpen %s~1..%s', commit, commit))
  end
end

return M
