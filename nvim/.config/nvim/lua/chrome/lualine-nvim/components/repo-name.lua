--- @class chrome.lualine-nvim.components.repo-name
local M = {}

-- Name per cwd, false while it resolves. Keyed by cwd, so a resolve a `cd` left behind still lands
-- in its own slot and needs no cancelling
--- @type table<string, string | false>
local names = {}
-- Shown while the current cwd resolves
local last_name

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

--- `M.get`'s async cache-miss path
--- @param cwd string
local function resolve_repo_name(cwd)
  local function finish(name)
    names[cwd] = name
    UI.statusline.refresh()
  end

  exec_cmd_async(cwd, { 'config', '--get', 'remote.origin.url' }, function(url)
    local repo_name = repo_name_from_url(url)
    if repo_name then
      finish(repo_name)
      return
    end

    local toplevel = vim.fs.root(cwd, '.git')
    if not toplevel then
      finish(vim.fs.basename(cwd))
      return
    end

    -- Worktrees of a bare repo show the bare repo's directory name (the toplevel's parent)
    local parent_dir = vim.fs.dirname(toplevel)
    exec_cmd_async(parent_dir, { 'rev-parse', '--is-bare-repository' }, function(is_bare)
      finish(vim.fs.basename(is_bare == 'true' and parent_dir or toplevel))
    end)
  end)
end

--- The repository name (remote URL => bare repo parent => toplevel dir => cwd name), never
--- blocking a render: a miss returns the last known name while an async chain resolves it
--- @return string name '' if not determinable
function M.get()
  local cwd = vim.uv.cwd()

  -- cwd can be nil (e.g. the directory was deleted), leaving nothing to resolve
  if cwd and names[cwd] == nil then
    names[cwd] = false
    -- Resolve outside the render path: even an async spawn costs a few ms, hitching the redraw
    vim.schedule(function()
      resolve_repo_name(cwd)
    end)
  end

  last_name = cwd and names[cwd] or last_name

  return last_name or vim.fs.basename(cwd) or ''
end

M.icon = Conf.icons.file_tree.FOLDER
M.color = 'blue'

return M
