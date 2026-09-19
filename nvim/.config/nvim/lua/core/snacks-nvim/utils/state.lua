--- @class snacks.picker.state.PickerDefaults
--- @field preview? boolean

--- @class core.snacks.utils.state
local M = {}

--- Pickers that participate in state management, with their default value per
--- state key. Add a picker here to enable state persistence for it.
local DEFAULTS = {
  files = { preview = true },
}

local state = {}

--- @param picker_name string
--- @param key string
--- @return boolean | number | string | nil
function M.get(picker_name, key)
  local defaults = DEFAULTS[picker_name]
  if not defaults then
    return nil
  end

  local picker_state = state[picker_name]
  local val = picker_state and picker_state[key]

  if val == nil then
    return defaults[key]
  end

  return val
end

--- @param picker_name string
--- @param key string
--- @param value boolean | number | string
function M.set(picker_name, key, value)
  if not DEFAULTS[picker_name] then
    return
  end

  state[picker_name] = state[picker_name] or {}
  state[picker_name][key] = value
end

--- @param picker_name string
--- @return boolean
function M.managed(picker_name)
  return DEFAULTS[picker_name] ~= nil
end

return M
