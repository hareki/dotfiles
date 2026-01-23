---@class utils.package
local M = {}

---Check if a lazy.nvim plugin is currently loaded
---@param name string The plugin name as registered in lazy.nvim
---@return boolean loaded True if the plugin has been loaded
function M.is_loaded(name)
  local lazy_config = require('lazy.core.config')
  return lazy_config.plugins[name] and lazy_config.plugins[name]._.loaded ~= nil
end

---Execute a callback when a plugin is loaded (or immediately if already loaded)
---@param name string The plugin name to wait for
---@param fn fun(name: string) Callback to execute when the plugin loads
---@return nil
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'LazyLoad',
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

---Get a plugin spec from lazy.nvim by name
---@param name string The plugin name
---@return table|nil plugin The plugin spec or nil if not found
function M.get_plugin(name)
  local lazy_config = require('lazy.core.config')
  return lazy_config.spec.plugins[name]
end

---Get the resolved opts for a lazy.nvim plugin
---@param name string The plugin name
---@return table opts The merged options table (empty table if plugin not found)
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local lazy_plugin = require('lazy.core.plugin')
  return lazy_plugin.values(plugin, 'opts', false)
end

return M
