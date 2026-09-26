local fn, fs, uv = vim.fn, vim.fs, vim.uv

-- nvim-lspconfig derives probe locations from exepath('ngserver'), but the mise
-- shim's realpath is the `mise` binary itself, so ngserver can't find
-- typescript / @angular/language-service and exits 1. Ask mise which install it
-- picks for the project and spawn that directly, so the probed bundle always
-- belongs to the running server (the `latest` install dir follows the newest
-- installed version, not the pinned one).
--
-- mise's npm backend hoists those deps into its virtual store and symlinks the
-- package into it, so realpath the package and take its grandparent to reach
-- the store's node_modules.
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
  return bin, real and fs.dirname(fs.dirname(real)) or nil
end

--- @param root_dir string
--- @return string
local function get_angular_core_version(root_dir)
  local package_json = fs.joinpath(root_dir, 'package.json')
  if not uv.fs_stat(package_json) then
    return ''
  end

  local ok, content = pcall(fn.readblob, package_json)
  if not ok or not content then
    return ''
  end

  local ok_decode, json = pcall(vim.json.decode, content)
  if not ok_decode or type(json) ~= 'table' then
    return ''
  end
  local deps = json.dependencies or {}
  local dev_deps = json.devDependencies or {}
  local version = deps['@angular/core'] or dev_deps['@angular/core'] or ''
  return version:match('%d+%.%d+%.%d+') or ''
end

return {
  opts = {
    -- angularls's default filetypes include plain typescript/html, so without a
    -- workspace guard ngserver would spawn in single-file mode in every JS/TS/HTML
    -- project. Its default root markers (angular.json/nx.json) already scope it.
    workspace_required = true,

    cmd = function(dispatchers, config)
      local root_dir = (config and config.root_dir) or fn.getcwd()
      local ngserver, ng_bundle = resolve_ngserver(root_dir)

      -- Project node_modules first so a project's own TypeScript/Angular
      -- versions win; the bundle is the fallback. 13.x bundles no TypeScript,
      -- so unlike 22.x it can't serve a project that hasn't been installed yet.
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

      -- An empty --angularCoreVersion is not treated as "unknown": it reaches the
      -- feature gates verbatim and fails every semver check, disabling @if/@for,
      -- @let, etc. Omitting the flag keeps them enabled via the server's own
      -- version auto-detection. (13.x doesn't know the flag and ignores it.)
      local core_version = get_angular_core_version(root_dir)
      if core_version ~= '' then
        vim.list_extend(cmd, { '--angularCoreVersion', core_version })
      end

      -- Spawn in the project so mise resolves `node` from the same config
      -- (e.g. a .nvmrc) that picked the ngserver install above.
      return vim.lsp.rpc.start(cmd, dispatchers, { cwd = root_dir })
    end,
  },
}
