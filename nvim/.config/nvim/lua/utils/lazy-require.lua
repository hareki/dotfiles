-- Source: https://github.com/tjdevries/lazy-require.nvim

---@tag lazy-require

---@brief [[
--- Lazy.nvim is a set of helper functions to make requiring modules easier.
---
--- Feel free to just copy and paste these functions out or just add as a
--- dependency for your plugin / configuration.
---
--- Hope you enjoy (and if you have other kinds of lazy loading you'd like to see,
--- feel free to submit some issues. Metatables can do many fun things).
---
--- Source:
--- - https://github.com/tjdevries/lazy-require.nvim
---
--- Support:
--- - https://github.com/sponsors/tjdevries
---
---@brief ]]

---@class utils.lazy-require
local M = {}

---Require on index - lazy load a module when first accessed
---Will only require the module after the first index of a module.
---Only works for modules that export a table.
---@param require_path string The module path to lazy-require
---@return table proxy A proxy table that defers require until first access
M.on_index = function(require_path)
  return setmetatable({}, {
    __index = function(_, key)
      return require(require_path)[key]
    end,

    __newindex = function(_, key, value)
      require(require_path)[key] = value
    end,
  })
end

---Require only when the module itself is called as a function
---If you want to require an exported value from the module,
---see instead `M.on_exported_call()`.
---@param require_path string The module path to lazy-require
---@return table proxy A callable proxy that defers require until invoked
M.on_module_call = function(require_path)
  return setmetatable({}, {
    __call = function(_, ...)
      return require(require_path)(...)
    end,
  })
end

---Require when an exported method is called
---Creates a new function wrapper. Cannot be used to compare functions,
---set new values, etc. Only useful for deferring require until the function is called.
---```lua
----- This is not loaded yet
---local lazy_mod = lazy.on_exported_call('my_module')
---local lazy_func = lazy_mod.exported_func
----- ... some time later
---lazy_func(42)  -- <- Only loads the module now
---```
---@param require_path string The module path to lazy-require
---@return table proxy A proxy table where each key returns a lazy function wrapper
M.on_exported_call = function(require_path)
  return setmetatable({}, {
    __index = function(_, k)
      return function(...)
        return require(require_path)[k](...)
      end
    end,
  })
end

return M
