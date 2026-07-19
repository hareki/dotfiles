local fn, fs, uv = vim.fn, vim.fs, vim.uv

-- nvim-lspconfig's default cmd derives ngserver's probe locations from
-- exepath('ngserver'), but mise puts a shim on $PATH whose realpath is the
-- `mise` binary itself (/opt/homebrew/.../bin/mise), so the heuristic resolves
-- to /opt/homebrew/Cellar and ngserver exits 1, unable to find typescript /
-- @angular/language-service. The mise global install bundles both under the
-- language-server's own node_modules, so point the probe locations there
-- directly. mise pins this tool to "latest" (mise/config.toml), and the alias
-- symlink tracks the installed version, so the path stays correct across
-- upgrades.
local ng_bundle = fn.expand(
  '~/.local/share/mise/installs/npm-angular-language-server/latest/lib/node_modules/@angular/language-server/node_modules'
)

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

      -- Project node_modules first so a project's own TypeScript/Angular
      -- versions win; the bundle is the fallback (and works even when the
      -- project hasn't been installed yet).
      local probe = {}
      local project_node = fs.joinpath(root_dir, 'node_modules')
      if uv.fs_stat(project_node) then
        table.insert(probe, project_node)
      end
      if uv.fs_stat(ng_bundle) then
        table.insert(probe, ng_bundle)
      end
      local probe_str = table.concat(probe, ',')

      local cmd = {
        'ngserver',
        '--stdio',
        '--tsProbeLocations',
        probe_str,
        '--ngProbeLocations',
        probe_str,
      }

      -- An empty --angularCoreVersion is not treated as "unknown": it reaches the
      -- feature gates verbatim and fails every semver check, disabling @if/@for,
      -- @let, etc. Omitting the flag keeps them enabled via the server's own
      -- version auto-detection.
      local core_version = get_angular_core_version(root_dir)
      if core_version ~= '' then
        vim.list_extend(cmd, { '--angularCoreVersion', core_version })
      end
      return vim.lsp.rpc.start(cmd, dispatchers)
    end,
  },
}
