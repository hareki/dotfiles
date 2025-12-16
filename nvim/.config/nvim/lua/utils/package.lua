---@class utils.package
local M = {}

function M.is_loaded(name)
  local lazy_config = require('lazy.core.config')
  return lazy_config.plugins[name] and lazy_config.plugins[name]._.loaded
end

-- LazyVim
---@param name string
---@param fn fun(name:string)
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

---@param name string
function M.get_plugin(name)
  return require('lazy.core.config').spec.plugins[name]
end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  return require('lazy.core.plugin').values(plugin, 'opts', false)
end

return M
