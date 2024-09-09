---@class util.common
local M = {}

M.aucmd = vim.api.nvim_create_autocmd
M.map = vim.keymap.set
M.unmap = vim.keymap.del

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

--- @param group string
--- @param style table
M.hl = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- @class ToggleConfig
--- @field title string
--- @field feature string
--- @field value boolean
--- @field lhs string
--- @field toggle_func fun()
--- @param config ToggleConfig
M.toggle_2 = function(config)
  --- @param feature string
  --- @param value number | boolean
  --- @param mode string -- past | present
  local function toggle_notify(feature, value, mode)
    local past = mode == "past"
    local message

    if type(value) == "boolean" then
      local action = value and "Enable" or "Disable"
      if past then
        action = action .. "d" -- Changes "Enable" to "Enabled" or "Disable" to "Disabled"
      end
      message = action .. " " .. feature
    elseif type(value) == "number" or type(value) == "string" then
      message = "Set " .. feature .. " to " .. tostring(value)
    else
      error("Unsupported value type: " .. type(value))
    end

    return message
  end

  local lhs = config.lhs
  local title = config.title
  local feature = config.feature
  local next_value = not config.value
  local notify = next_value and LazyVim.info or LazyVim.warn
  local toggle_func = config.toggle_func

  Util.map("n", lhs, function()
    notify(toggle_notify(feature, next_value, "past"), { title = title })
    toggle_func()
  end)

  require("which-key").add({
    {
      lhs,
      desc = function()
        return toggle_notify(feature, not next_value, "present")
      end,
    },
  })
end

M.get_initial_path = function()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(tostring(first_arg), ":p")

  return initial_path
end

M.remove_lualine_component = function(name, tbl)
  -- Iterate through the table in reverse to avoid issues when removing elements (skipping elements)
  for i = #tbl, 1, -1 do
    if tbl[i][1] == name then
      table.remove(tbl, i)
    end
  end
end

--- Ensures that the nested tables exist in the given table.
--- @param t table The table to operate on.
--- @vararg string The keys to ensure nested tables for.
--- @return table nested_table the innermost table that was ensured.
function M.ensure_nested_table(t, ...)
  local keys = { ... }
  for _, key in ipairs(keys) do
    if t[key] == nil then
      t[key] = {}
    end
    t = t[key]
  end
  return t
end

return M
