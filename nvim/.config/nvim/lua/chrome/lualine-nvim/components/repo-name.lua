--- @class chrome.lualine.components.repo-name
local M = {}

-- `name`, `last_cwd` and `toplevel` are written together (in `finish`), so an abandoned resolve
-- can't pair a name with another repo's toplevel; `pending_cwd` is the cwd a resolve runs for
local repo_cache = {
  name = nil,
  last_cwd = nil,
  toplevel = nil,
  pending_cwd = nil,
}

--- Run a git command asynchronously, passing its trimmed output to `cb` on the main loop
--- (via `vim.schedule`), where it may touch vim APIs and module state
--- @param cmd string The git command to execute (without 'git' prefix)
--- @param cwd string | nil The directory to run the command in (default: current)
--- @param cb fun(output: string | nil) Receives trimmed stdout, or nil on error or empty output
--- @return nil
local function exec_cmd_async(cmd, cwd, cb)
  local args = vim.split(cmd, '%s+')
  local git_cmd = { 'git' }

  if cwd then
    vim.list_extend(git_cmd, { '-C', cwd })
  end

  vim.list_extend(git_cmd, args)

  vim.system(git_cmd, { text = true }, function(result)
    vim.schedule(function()
      local output = result.code == 0 and vim.trim(result.stdout or '') or ''
      cb(output ~= '' and output or nil)
    end)
  end)
end

--- Extract the repository name from a git remote URL
--- Strips .git suffix and extracts the last path component.
--- @param url string | nil
--- @return string | nil name The repository name, or nil if not extractable
local function repo_name_from_url(url)
  if not url then
    return nil
  end

  url = url:gsub('%.git$', '')

  return url:match('([^/]+)$')
end

--- Returns the last component of the path (directory/file name).
--- @param path string
--- @return string | nil name The last path component, or nil if invalid
local function get_repo_name_from_path(path)
  return path:match('([^/\\]+)$')
end

--- Async continuation of `M.get`'s cache-miss path; a cwd change between steps abandons the
--- chain, and the next render restarts it for the new cwd
--- @param cwd string The cwd this chain resolves for
local function resolve_repo_name(cwd)
  --- Mark this chain done, unless a chain for a newer cwd has taken over the slot
  local function release_pending()
    if repo_cache.pending_cwd == cwd then
      repo_cache.pending_cwd = nil
    end
  end

  -- A cwd that changed and changed back compares equal, which is correct
  local function superseded()
    if vim.uv.cwd() ~= cwd then
      release_pending()
      return true
    end

    return false
  end

  local function finish(name, toplevel)
    repo_cache.name = name
    repo_cache.last_cwd = cwd
    repo_cache.toplevel = toplevel
    release_pending()

    UI.statusline.refresh()
  end

  exec_cmd_async('rev-parse --show-toplevel', nil, function(toplevel)
    if superseded() then
      return
    end

    -- Still in the cached name's repo: re-key the fast path and stop. A nil toplevel doesn't count:
    -- outside a repo, nil == nil would keep a stale name from a previous directory
    if repo_cache.name and toplevel and repo_cache.toplevel == toplevel then
      repo_cache.last_cwd = cwd
      release_pending()
      return
    end

    exec_cmd_async('config --get remote.origin.url', nil, function(url)
      if superseded() then
        return
      end

      local repo_name = repo_name_from_url(url)
      if repo_name then
        finish(repo_name, toplevel)
        return
      end

      local function finish_from_path()
        local name = toplevel and get_repo_name_from_path(toplevel) or get_repo_name_from_path(cwd)
        finish(name or 'Unknown', toplevel)
      end

      -- Worktrees of a bare repo show the bare repo's directory name (the toplevel's parent)
      local parent_dir = toplevel and toplevel:match('(.+)/[^/]+$')
      if not parent_dir then
        finish_from_path()
        return
      end

      exec_cmd_async('rev-parse --is-bare-repository', parent_dir, function(is_bare)
        if superseded() then
          return
        end

        if is_bare == 'true' then
          local parent_repo_name = get_repo_name_from_path(parent_dir)
          if parent_repo_name then
            finish(parent_repo_name, toplevel)
            return
          end
        end

        finish_from_path()
      end)
    end)
  end)
end

--- The repository name (remote URL => bare repo parent => toplevel dir => cwd name), never
--- blocking a render: a miss returns the last known name while an async chain refreshes it
--- @return string name The repository name, or '' if not determinable
function M.get()
  local current_cwd = vim.uv.cwd()

  if repo_cache.name and repo_cache.last_cwd == current_cwd then
    return repo_cache.name
  end

  local placeholder = repo_cache.name or get_repo_name_from_path(current_cwd or '') or ''

  -- cwd can be nil (e.g. the directory was deleted); nothing to resolve then
  if not current_cwd then
    return placeholder
  end

  -- A resolve for this cwd is already in flight; keep rendering the stale
  -- value until it lands
  if repo_cache.pending_cwd == current_cwd then
    return placeholder
  end

  repo_cache.pending_cwd = current_cwd
  -- Kick the resolve outside the render path: even async spawn initiation
  -- costs a few ms, which would still hitch the redraw that missed the cache
  vim.schedule(function()
    resolve_repo_name(current_cwd)
  end)

  return placeholder
end

M.icon = Conf.icons.file_tree.FOLDER
M.color = 'blue'

return M
