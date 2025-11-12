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

---Extend multiple arrays into a single array
---@param ... table[]
---@return table
function M.list_extend(...)
  local result = {}
  for _, keymap_array in ipairs({ ... }) do
    if keymap_array then
      vim.list_extend(result, keymap_array)
    end
  end
  return result
end

function M.is_float_win(win)
  local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
  return ok and cfg and ((cfg.relative and cfg.relative ~= '') or cfg.external == true)
end

function M.repaint_render_markdown(win)
  local render_md = require('render-markdown')
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  M.noautocmd(function()
    vim.api.nvim_win_call(win, function()
      render_md.enable()
    end)
  end)
end

---Focus a window without triggering autocommands.
---If current window is a floating markdown preview, repaint it after moving.
---@param win integer|nil
---@return boolean success
function M.focus_win(win)
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local function is_markdown_buf(win_id)
    local buf = vim.api.nvim_win_get_buf(win_id)
    return vim.bo[buf].filetype == 'markdown'
  end

  local src = vim.api.nvim_get_current_win()
  local need_repaint = M.is_float_win(src) and is_markdown_buf(src)

  M.noautocmd(function()
    vim.api.nvim_set_current_win(win)
  end)

  if need_repaint then
    M.repaint_render_markdown(src)
  end

  return true
end

---Count the number of string keys in a table
---@param t table
---@return integer
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
