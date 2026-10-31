local common = require('utils.common')

--- @class core.lsp.nvim-lspconfig.utils.typescript
local M = {}

--- @class core.lsp.nvim-lspconfig.utils.typescript.Owner
--- @field server 'tsc' | 'vtsls'
--- @field root string The directory holding the install for tsc, the project root for vtsls

local fs = vim.fs

-- Stateless, and read before lsp/vtsls.lua replaces it: that file requires this module first
local project_root_dir = vim.lsp.config.vtsls.root_dir --[[@as fun(bufnr: integer, on_dir: fun(root_dir?: string))]]

-- Native first: Microsoft's alias setup keeps TS 6 as `typescript` and installs TS 7 under this name
local PACKAGES = { '@typescript/native', 'typescript' }

-- Sticky per directory: root_dir can't detach, so a changed answer would attach a second server
--- @type table<string, core.lsp.nvim-lspconfig.utils.typescript.Owner>
local owners = {}

--- @param version? string A version or range, possibly an `npm:name@range` alias
--- @return boolean
local function is_native(version)
  local major = version and version:match('(%d+)[^@]*$')
  return major ~= nil and tonumber(major) >= 7
end

--- @param dir string
--- @return string?
local function installed_version(dir)
  for _, name in ipairs(PACKAGES) do
    local manifest = common.read_json(fs.joinpath(dir, 'node_modules', name, 'package.json'))
    if manifest then
      return manifest.version
    end
  end
end

--- @param dir string
--- @return string?
local function declared_version(dir)
  local manifest = common.read_json(fs.joinpath(dir, 'package.json')) or {}

  for _, name in ipairs(PACKAGES) do
    local version = vim.tbl_get(manifest, 'devDependencies', name)
      or vim.tbl_get(manifest, 'dependencies', name)
    if version then
      return version
    end
  end
end

--- The nearest install between the file and the project root decides, else the nearest declaration
--- @param file string
--- @param project_root string
--- @return core.lsp.nvim-lspconfig.utils.typescript.Owner? owner nil when TS 7+ is declared but not installed
local function find_owner(file, project_root)
  local vtsls = { server = 'vtsls', root = project_root }
  local declared

  for dir in fs.parents(file) do
    local installed = installed_version(dir)
    if installed then
      return is_native(installed) and { server = 'tsc', root = dir } or vtsls
    end

    declared = declared or declared_version(dir)
    if dir == project_root then
      break
    end
  end

  if not is_native(declared) then
    return vtsls
  end
end

--- @param bufnr integer
--- @param callback fun(owner: core.lsp.nvim-lspconfig.utils.typescript.Owner)
local function with_owner(bufnr, callback)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = fs.dirname(file)
  if owners[dir] then
    return callback(owners[dir])
  end

  project_root_dir(bufnr, function(project_root)
    owners[dir] = find_owner(file, project_root)

    if owners[dir] then
      callback(owners[dir])
    else
      -- No fallback: vtsls would run its bundled TS in a project configured for TS 7
      vim.notify_once(
        string.format('%s needs TypeScript installed for tsc to start', project_root),
        vim.log.levels.WARN
      )
    end
  end)
end

--- `root_dir` for `server`, which starts only in the directories it owns
--- @param server 'tsc' | 'vtsls'
--- @return fun(bufnr: integer, on_dir: fun(root_dir?: string))
function M.root_dir(server)
  return function(bufnr, on_dir)
    with_owner(bufnr, function(owner)
      if owner.server == server then
        on_dir(owner.root)
      end
    end)
  end
end

--- @param dir string
--- @return string?
local function real_install(dir)
  for _, name in ipairs(PACKAGES) do
    local real = vim.uv.fs_realpath(fs.joinpath(dir, 'node_modules', name))
    if real then
      return real
    end
  end
end

--- One tsc per real install: pnpm links every package's TypeScript to one store entry, and the
--- server finds each file's tsconfig itself, so any of those packages can be the client's root
--- @param client vim.lsp.Client
--- @param config vim.lsp.ClientConfig
--- @return boolean
function M.reuse_client(client, config)
  return client.name == config.name
    and not client:is_stopped()
    and real_install(client.root_dir) == real_install(config.root_dir)
end

--- Keymap callback applying one server's source action
--- @param client_id integer
--- @param kind string
--- @return fun()
local function source_action(client_id, kind)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = {
        only = { kind },
        diagnostics = {},
      },
      -- oxlint also answers source.fixAll on a fixable lint; two actions would open a picker
      filter = function(_, action_client_id)
        return action_client_id == client_id
      end,
    })
  end
end

--- Map a server's import source actions on the buffers it attaches to
--- @param server 'tsc' | 'vtsls'
--- @param remove_unused string Code action kind
--- @param add_missing string Code action kind
function M.map_import_actions(server, remove_unused, add_missing)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup(
      'core.lsp.nvim-lspconfig.utils.typescript.attach-' .. server,
      { clear = true }
    ),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if not (client and client.name == server) then
        return
      end

      local map = common.buf_mapper(args.buf, { prefix = 'TypeScript LSP: ' })

      map('n', '<leader>cu', source_action(client.id, remove_unused), 'Remove Unused Imports')
      map('n', '<leader>ci', source_action(client.id, add_missing), 'Add Missing Imports')
    end,
  })
end

return M
