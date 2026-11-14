local icons = require('config.icons')

--- @class utils.ui.integration.Host
--- @field icon string
--- @field color string Catppuccin palette key for the label's foreground
--- @field label string

--- Entry point: the tools that open nvim as their editor set NVIM_INTEGRATION to one of these keys
--- (git's `core.editor`, lazygit's edit commands and Claude Code's `nvim-claude` shim, all in the
--- dotfiles), so the keys stay stable: a value that is none of them aborts the boot
--- @type table<string, utils.ui.integration.Host>
local HOSTS = {
  lazygit = { icon = icons.git.LAZYGIT, color = 'blue', label = 'Lazygit' },
  git = { icon = icons.git.GIT, color = 'red', label = 'Git' },
  ['claude-code'] = { icon = icons.cmp_kinds.Claude, color = 'peach', label = 'Claude Code' },
}

--- Resolve the host from NVIM_INTEGRATION, raising on an unknown value
--- @return utils.ui.integration.Host? host nil when nvim runs standalone
local function resolve_host()
  local name = vim.env.NVIM_INTEGRATION
  if not name then
    return nil
  end

  local host = HOSTS[name]
  if not host then
    local names = vim.tbl_keys(HOSTS)
    table.sort(names)
    error(
      string.format(
        'Invalid NVIM_INTEGRATION %q, expected one of: %s',
        name,
        table.concat(names, ', ')
      ),
      0
    )
  end

  return host
end

--- The integration: the reduced mode nvim runs in when a tool opens it as its editor, its
--- statusline the tool's label in place of lualine
--- @class utils.ui.integration
--- @field host? utils.ui.integration.Host The tool that opened this nvim, if any
local M = {
  -- Resolved on load (config.globals) so an invalid value aborts the boot before anything else runs
  host = resolve_host(),
}

local GROUP = 'StatusLineIntegration'

--- The host label's highlight group, for catppuccin's custom_highlights; none standalone
--- @param palette utils.ui.catppuccin-nvim.Palette
--- @return table<string, vim.api.keyset.highlight> groups
function M.highlights(palette)
  if not M.host then
    return {}
  end
  return { [GROUP] = { fg = palette[M.host.color] } }
end

--- The 'statusline' showing the host's label; nil standalone
--- @return string? statusline
function M.statusline()
  if not M.host then
    return nil
  end
  return string.format(' %%#%s#%s %s', GROUP, M.host.icon, M.host.label)
end

return M
