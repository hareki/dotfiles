---@class util.git
local M = {}

-- Start with the default branch format
local branch_display_mode = Constant.git.BRANCH_FORMATS.TASK_ID_ONLY

local task_name_start_length = 999
local task_name_end_length = 10
local max_task_name_length = task_name_start_length + task_name_end_length

-- Initialize a cache table to store the repository name and last known CWD
local repo_cache = {
  name = nil,
  last_cwd = nil,
}

-- Helper function to check valid branch format
function M.is_valid_branch_format(format)
  for _, value in pairs(Constant.git.BRANCH_FORMATS) do
    if value == format then
      return true
    end
  end
  return false
end

function M.set_branch_name_format(format_name)
  if M.is_valid_branch_format(format_name) then
    branch_display_mode = format_name
    LazyVim.notify("Branch name format set to " .. format_name)
    require("lualine").refresh()
  else
    LazyVim.error("Invalid branch name format: " .. format_name)
  end
end

-- Format branch name based on the current display mode
function M.format_branch_name(branch_name)
  -- Check if the branch name follows the ClickUp format
  local is_clickup_format = branch_name:match("^CU%-%w+_.+_.+$")
  if not is_clickup_format then
    return branch_name
  end

  -- Extract the prefix (task ID), task name, and author name
  local prefix, task_name, author_name = branch_name:match("^(CU%-%w+)_([^_]+)_(.+)$")

  -- Handle formatting for different display modes
  if branch_display_mode == Constant.git.BRANCH_FORMATS.TASK_ID_ONLY then
    return prefix
  elseif branch_display_mode == Constant.git.BRANCH_FORMATS.TASK_ID_AND_NAME then
    -- Display task ID and formatted task name
    local formatted_task_name
    if #task_name > max_task_name_length then
      -- Show start and end parts of the task name with ellipsis
      formatted_task_name = task_name:sub(1, task_name_start_length) .. "..." .. task_name:sub(-task_name_end_length)
    else
      formatted_task_name = task_name
    end
    return prefix .. "_" .. formatted_task_name
  elseif branch_display_mode == Constant.git.BRANCH_FORMATS.TASK_ID_AND_AUTHOR then
    -- Display task ID and author name
    return prefix .. "_" .. author_name
  end
end

-- Helper function to execute a shell command and return its output
function M.exec_cmd(cmd, cwd)
  local full_cmd = cmd
  if cwd then
    -- Use 'git -C <cwd> <cmd>' to execute the command in the specified directory
    full_cmd = 'git -C "' .. cwd .. '" ' .. cmd
  end
  -- Open a pipe to execute the command, redirecting stderr to /dev/null
  local handle = io.popen(full_cmd .. " 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result ~= "" then
      -- Trim whitespace and newlines
      return result:gsub("%s+", "")
    end
  end
  return nil
end

function M.get_repo_name_from_remote()
  -- Execute the basename command to strip the .git suffix
  -- Command: basename -s .git $(git config --get remote.origin.url)
  local cmd = "basename -s .git $(git config --get remote.origin.url)"
  local repo_name = M.exec_cmd(cmd)
  if repo_name and repo_name ~= "" then
    return repo_name
  end
  return nil
end

-- Function to check if a given directory is a bare repository
function M.is_bare_repo(path)
  if not path or path == "" then
    return false
  end
  local result = M.exec_cmd("rev-parse --is-bare-repository", path)
  return result == "true"
end

-- Function to extract the repository name from a given path
function M.get_repo_name_from_path(path)
  return path:match("([^/\\]+)$")
end

-- Function to get the repository name following the refined logic
function M.get_repo_name()
  local current_cwd = Util.cwd()

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
  local toplevel = M.exec_cmd("rev-parse --show-toplevel")
  if toplevel and toplevel ~= "" then
    -- Extract the parent directory of the top-level directory
    local parent_dir = toplevel:match("(.+)/[^/\\]+$") or toplevel:match("(.+)\\[^\\]+$")
    if parent_dir and parent_dir ~= "" then
      -- Check if the parent directory is a bare repository
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
  repo_cache.name = cwd_name or "Unknown"
  return repo_name
end

return M
