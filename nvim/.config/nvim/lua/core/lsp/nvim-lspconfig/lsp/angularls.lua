local common = require('utils.common')

local fs, uv = vim.fs, vim.uv

-- lspconfig probes ngserver's deps from exepath(), but the mise shim's realpath is `mise` itself;
-- spawn the install `mise which` picks (the npm store is the package realpath's grandparent)
--- @param root_dir string
--- @return string ngserver
--- @return string? bundle
local function resolve_ngserver(root_dir)
  local which = vim.system({ 'mise', 'which', 'ngserver' }, { cwd = root_dir, text = true }):wait()
  if which.code ~= 0 then
    return 'ngserver', nil
  end

  -- <install>/node_modules/.bin/ngserver => <install>/node_modules/@angular/language-server
  local bin = vim.trim(which.stdout)
  local pkg = fs.joinpath(fs.dirname(fs.dirname(bin)), '@angular', 'language-server')
  local real = uv.fs_realpath(pkg)
  return bin, real and fs.dirname(fs.dirname(real))
end

--- @param root_dir string
--- @return string
local function get_angular_core_version(root_dir)
  local json = common.read_json(fs.joinpath(root_dir, 'package.json')) or {}
  local deps = json.dependencies or {}
  local dev_deps = json.devDependencies or {}
  local version = deps['@angular/core'] or dev_deps['@angular/core'] or ''
  return version:match('%d+%.%d+%.%d+') or ''
end

return {
  opts = {
    -- Its filetypes include plain ts/html, so ngserver would otherwise spawn in every such project
    workspace_required = true,

    cmd = function(dispatchers, config)
      local root_dir = config.root_dir
      local ngserver, ng_bundle = resolve_ngserver(root_dir)

      -- Project node_modules first so its own TypeScript/Angular versions win over the bundle; 13.x
      -- bundles no TypeScript, so it can't serve a project whose deps aren't installed yet
      local probe = {}
      local project_node = fs.joinpath(root_dir, 'node_modules')
      if uv.fs_stat(project_node) then
        table.insert(probe, project_node)
      end
      if ng_bundle then
        table.insert(probe, ng_bundle)
      end
      local probe_str = table.concat(probe, ',')

      local cmd = {
        ngserver,
        '--stdio',
        '--tsProbeLocations',
        probe_str,
        '--ngProbeLocations',
        probe_str,
      }

      -- An empty --angularCoreVersion fails every semver gate (disabling @if/@for, @let, ...), so
      -- omit it and let the server detect the version (13.x ignores the flag)
      local core_version = get_angular_core_version(root_dir)
      if core_version ~= '' then
        vim.list_extend(cmd, { '--angularCoreVersion', core_version })
      end

      -- Spawn in the project so mise resolves `node` from the config that picked ngserver
      return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root_dir })
    end,
  },
}
