---@class snacks.picker.state.PickerDefaults
---@field preview? boolean

local M = {}

---Pickers that participate in state management.
---Add picker names here to enable state persistence.
local PICKERS_WITH_STATE = {
  files = true,
}

---Default values per picker, per state key.
---Each picker can define its own defaults for any state.
local DEFAULTS = {
  files = { preview = true },
}

local state = {}

---@param picker_name string
---@param key string
---@return boolean|number|string|nil
function M.get(picker_name, key)
  if not PICKERS_WITH_STATE[picker_name] then
    return nil
  end

  local picker_state = state[picker_name]
  local val = picker_state and picker_state[key]

  if val == nil then
    local defs = DEFAULTS[picker_name]
    return defs and defs[key]
  end

  return val
end

---@param picker_name string
---@param key string
---@param value boolean|number|string
function M.set(picker_name, key, value)
  if not PICKERS_WITH_STATE[picker_name] then
    return
  end

  state[picker_name] = state[picker_name] or {}
  state[picker_name][key] = value
end

---@param picker_name string
---@return boolean
function M.managed(picker_name)
  return PICKERS_WITH_STATE[picker_name] == true
end

return M
