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

--- Run a git command asynchronously, calling `cb` on the main loop, where it may touch vim APIs
--- @param cwd string
--- @param args string[]
--- @param cb fun(output: string | nil) Receives trimmed stdout, or nil on error or empty output
--- @return nil
local function exec_cmd_async(cwd, args, cb)
  vim.system(vim.list_extend({ 'git', '-C', cwd }, args), { text = true }, function(result)
    vim.schedule(function()
      local output = result.code == 0 and vim.trim(result.stdout) or ''
      cb(output ~= '' and output or nil)
    end)
  end)
end

--- The last path component of a git remote URL, minus its .git suffix
--- @param url string | nil
--- @return string | nil name
local function repo_name_from_url(url)
  if not url then
    return nil
  end

  url = url:gsub('%.git$', '')

  return url:match('([^/]+)$')
end

--- `M.get`'s async cache-miss path; a cwd change abandons the chain for the next render to restart
--- @param cwd string
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

  local toplevel = vim.fs.root(cwd, '.git')

  -- Still in the cached name's repo: re-key the fast path and stop. A nil toplevel doesn't count:
  -- outside a repo, nil == nil would keep a stale name from a previous directory
  if repo_cache.name and toplevel and repo_cache.toplevel == toplevel then
    repo_cache.last_cwd = cwd
    release_pending()
    return
  end

  exec_cmd_async(cwd, { 'config', '--get', 'remote.origin.url' }, function(url)
    if superseded() then
      return
    end

    local repo_name = repo_name_from_url(url)
    if repo_name then
      finish(repo_name, toplevel)
      return
    end

    local path_name = vim.fs.basename(toplevel or cwd)
    if not toplevel then
      finish(path_name, toplevel)
      return
    end

    -- Worktrees of a bare repo show the bare repo's directory name (the toplevel's parent)
    local parent_dir = vim.fs.dirname(toplevel)
    exec_cmd_async(parent_dir, { 'rev-parse', '--is-bare-repository' }, function(is_bare)
      if not superseded() then
        finish(is_bare == 'true' and vim.fs.basename(parent_dir) or path_name, toplevel)
      end
    end)
  end)
end

--- The repository name (remote URL => bare repo parent => toplevel dir => cwd name), never
--- blocking a render: a miss returns the last known name while an async chain refreshes it
--- @return string name '' if not determinable
function M.get()
  local current_cwd = vim.uv.cwd()

  if repo_cache.name and repo_cache.last_cwd == current_cwd then
    return repo_cache.name
  end

  local placeholder = repo_cache.name or vim.fs.basename(current_cwd) or ''

  -- cwd can be nil (e.g. the directory was deleted); nothing to resolve then
  if not current_cwd then
    return placeholder
  end

  -- A resolve for this cwd is already in flight; keep rendering the stale value
  if repo_cache.pending_cwd == current_cwd then
    return placeholder
  end

  repo_cache.pending_cwd = current_cwd
  -- Resolve outside the render path: even an async spawn costs a few ms, hitching the redraw
  vim.schedule(function()
    resolve_repo_name(current_cwd)
  end)

  return placeholder
end

M.icon = Conf.icons.file_tree.FOLDER
M.color = 'blue'

return M
