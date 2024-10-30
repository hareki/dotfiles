---@class util.common
local M = {}

M.aucmd = vim.api.nvim_create_autocmd
M.clear_aucmd = vim.api.nvim_clear_autocmds

M.map = vim.keymap.set
M.unmap = vim.keymap.del

M.cwd = vim.fn.getcwd

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

--- @param group string
--- @param style table
M.hl = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
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
--- @param key_string string The dot-separated string representing the nested keys.
--- @return table nested_table the innermost table that was ensured.
function M.ensure_nested(t, key_string)
  local keys = {}
  for key in key_string:gmatch("[^%.]+") do
    table.insert(keys, key)
  end

  for _, key in ipairs(keys) do
    if t[key] == nil then
      t[key] = {}
    end
    t = t[key]
  end
  return t
end

return M
