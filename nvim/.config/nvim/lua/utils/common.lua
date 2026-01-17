---@class utils.common
local M = {}

---Execute a function without triggering autocommands
---@param fn fun()
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, err = pcall(fn)
  vim.o.eventignore = ei
  if not ok then
    error(err, 0)
  end
end

---Extend multiple arrays into a single flattened array
---@param ... table[] Variable number of arrays to concatenate
---@return table result A new array containing all elements from the input arrays
function M.list_extend(...)
  local result = {}
  for _, keymap_array in ipairs({ ... }) do
    if keymap_array then
      vim.list_extend(result, keymap_array)
    end
  end
  return result
end

---Check if a window is a floating window
---@param win integer Window handle (0 for current)
---@return boolean True if the window is floating
function M.is_float_win(win)
  local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
  return ok and cfg and ((cfg.relative and cfg.relative ~= '') or cfg.external == true)
end

local function repaint_render_markdown(win_id)
  local render_md = require('render-markdown')
  if not vim.api.nvim_win_is_valid(win_id) then
    return
  end

  M.noautocmd(function()
    vim.api.nvim_win_call(win_id, function()
      render_md.enable()
    end)
  end)
end

local function is_markdown_buf(win_id)
  local buf = vim.api.nvim_win_get_buf(win_id)
  return vim.bo[buf].filetype == 'markdown'
end

---Focus a window without triggering autocommands
---If current window is a floating markdown preview, repaint it after focus change.
---@param win integer|nil Window handle to focus (0/nil returns false)
---@return boolean success True if window was successfully focused
function M.focus_win(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local src = vim.api.nvim_get_current_win()
  local need_repaint = M.is_float_win(src) and is_markdown_buf(src)

  M.noautocmd(function()
    vim.api.nvim_set_current_win(win)
  end)

  if need_repaint then
    repaint_render_markdown(src)
  end

  return true
end

---Count the number of string keys in a table (ignores numeric keys)
---@param t table The table to count string keys in
---@return integer count The number of keys with type 'string'
function M.count_string_keys(t)
  local n = 0
  for k in pairs(t) do
    if type(k) == 'string' then
      n = n + 1
    end
  end
  return n
end

return M
