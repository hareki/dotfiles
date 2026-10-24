--- @class utils.ui.statusline.Integration
--- @field icon string
--- @field color string Catppuccin palette key for the label's foreground
--- @field label string

--- Host tools that launch nvim as their editor, keyed by the NVIM_INTEGRATION value they set
--- @type table<string, utils.ui.statusline.Integration>
local integrations = {
  lazygit = { icon = Conf.icons.git.LAZYGIT, color = 'blue', label = 'Lazygit' },
  git = { icon = Conf.icons.git.GIT, color = 'red', label = 'Git' },
  ['claude-code'] = { icon = Conf.icons.cmp_kinds.Claude, color = 'peach', label = 'Claude Code' },
}

--- Resolve the host integration from NVIM_INTEGRATION, raising on an unknown value
--- @return utils.ui.statusline.Integration? integration nil when nvim runs standalone
local function resolve_integration()
  local name = vim.env.NVIM_INTEGRATION
  if not name then
    return nil
  end

  local integration = integrations[name]
  if not integration then
    local names = vim.tbl_keys(integrations)
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

  return integration
end

--- @class utils.ui.statusline
--- @field integration? utils.ui.statusline.Integration Host tool that launched nvim, if any
local M = {
  -- Resolved on load (config.globals) so an invalid value aborts the boot before anything else runs
  integration = resolve_integration(),
}

--- Check if the lualine statusline is enabled (host integrations show their label instead)
--- @return boolean enabled
function M.enabled()
  return M.integration == nil
end

--- Refresh the lualine statusline if lualine is loaded
--- @return nil
function M.refresh()
  if package.loaded['lualine'] then
    local lualine = require('lualine')
    lualine.refresh({ place = { 'statusline' } })
  end
end

return M
