--- @class utils.package
local M = {}

--- Check if a lazy.nvim plugin is currently loaded
--- @param name string The plugin name as registered in lazy.nvim
--- @return boolean loaded True if the plugin has been loaded
function M.is_loaded(name)
  local lazy_config = require('lazy.core.config')
  return lazy_config.plugins[name] and lazy_config.plugins[name]._.loaded ~= nil
end

--- Execute a callback when a plugin is loaded (or immediately if already loaded)
--- @param name string The plugin name to wait for
--- @param fn fun(name: string) Callback to execute when the plugin loads
--- @return nil
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

return M
