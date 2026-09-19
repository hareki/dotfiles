--- @class utils.common
local M = {}

--- Execute a function without triggering autocommands
--- @param fn fun()
function M.noautocmd(fn)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  local ok, err = pcall(fn)
  vim.o.eventignore = ei
  if not ok then
    error(err, 0)
  end
end

--- Check if a window is a floating window
--- @param win integer Window handle (0 for current)
--- @return boolean True if the window is floating
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
      -- buf_enable scopes to the float's buffer; enable() would flip the
      -- plugin's global state and force-render every attached buffer
      render_md.buf_enable()
    end)
  end)
end

local function is_markdown_buf(win_id)
  local buf = vim.api.nvim_win_get_buf(win_id)
  return vim.bo[buf].filetype == 'markdown'
end

--- Focus a window without triggering autocommands
--- If current window is a floating markdown preview, repaint it after focus change.
--- @param win integer | nil Window handle to focus (0/nil returns false)
--- @return boolean success True if window was successfully focused
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

--- Snapshot a buffer's own mapping, in the maparg() form restore_buf_keymap reinstates
--- @param buf integer
--- @param mode string
--- @param lhs string
--- @return table | nil map nil when the buffer is invalid or has no buffer-local mapping for lhs
function M.get_buf_keymap(buf, mode, lhs)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  return vim.api.nvim_buf_call(buf, function()
    local map = vim.fn.maparg(lhs, mode, false, true)
    return map.buffer == 1 and map or nil
  end)
end

--- Reinstate a mapping captured by get_buf_keymap; mapset() keeps its Lua
--- callback, desc and flags intact
--- @param buf integer
--- @param mode string
--- @param map table
--- @return nil
local function restore_buf_keymap(buf, mode, map)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.mapset(mode, false, map)
  end)
end

--- @class utils.common.KeymapLayer
--- @field rhs string | function
--- @field opts vim.keymap.set.Opts

--- Popup overrides per buffer-local key, oldest first; `base` is the buffer's own
--- mapping from before the first override (nil when the key was unmapped)
--- @type table<string, { base: table?, layers: utils.common.KeymapLayer[] }>
local override_stacks = {}

--- Map keys on a buffer for as long as a popup lives. Overrides of the same key
--- stack, so whatever order overlapping popups close in, releasing one keeps the
--- newest remaining override active, or reinstates the buffer's own mapping once
--- none remain
--- @param buf integer
--- @param maps { [1]: string | string[], [2]: string, [3]: string | function, [4]?: vim.keymap.set.Opts }[] Mode(s), lhs, rhs and opts of each override
--- @return fun() release Undoes every override of this call; later calls are no-ops
function M.override_buf_keymaps(buf, maps)
  --- @type { key: string, mode: string, lhs: string, layer: utils.common.KeymapLayer }[]
  local pushed = {}

  for _, map in ipairs(maps) do
    local modes, lhs, rhs, opts = map[1], map[2], map[3], map[4]
    if type(modes) == 'string' then
      modes = { modes }
    end
    local layer = { rhs = rhs, opts = vim.tbl_extend('force', opts or {}, { buffer = buf }) }

    for _, mode in ipairs(modes) do
      local key = string.format('%d %s %s', buf, mode, lhs)
      override_stacks[key] = override_stacks[key]
        or { base = M.get_buf_keymap(buf, mode, lhs), layers = {} }
      table.insert(override_stacks[key].layers, layer)
      vim.keymap.set(mode, lhs, rhs, layer.opts)
      pushed[#pushed + 1] = { key = key, mode = mode, lhs = lhs, layer = layer }
    end
  end

  local released = false
  return function()
    if released then
      return
    end
    released = true

    for _, entry in ipairs(pushed) do
      local stack = override_stacks[entry.key]
      local was_active = stack.layers[#stack.layers] == entry.layer
      for index, layer in ipairs(stack.layers) do
        if layer == entry.layer then
          table.remove(stack.layers, index)
          break
        end
      end

      local top = stack.layers[#stack.layers]
      if not top then
        override_stacks[entry.key] = nil
      end

      -- A newer override still covering this one keeps its mapping active
      if was_active and vim.api.nvim_buf_is_valid(buf) then
        if top then
          vim.keymap.set(entry.mode, entry.lhs, top.rhs, top.opts)
        elseif stack.base then
          restore_buf_keymap(buf, entry.mode, stack.base)
        else
          pcall(vim.keymap.del, entry.mode, entry.lhs, { buffer = buf })
        end
      end
    end
  end
end

return M
