--- @class utils.keymap
local M = {}

--- Buffer-local `vim.keymap.set` sharing one opts table, with an optional desc prefix
--- @param buf integer
--- @param opts? vim.keymap.set.Opts | { prefix?: string }
--- @return fun(mode: string | string[], lhs: string | string[], rhs: string | function, desc: string) map
function M.buf_mapper(buf, opts)
  local base = vim.tbl_extend('force', opts or {}, { buf = buf })
  local prefix = base.prefix or ''
  base.prefix = nil

  return function(mode, lhs, rhs, desc)
    if type(lhs) == 'string' then
      lhs = { lhs }
    end
    local keymap_opts = vim.tbl_extend('force', base, { desc = prefix .. desc })
    for _, key in ipairs(lhs) do
      vim.keymap.set(mode, key, rhs, keymap_opts)
    end
  end
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

--- Reinstate a mapping captured by get_buf_keymap; mapset() keeps its callback, desc and flags
--- @param buf integer
--- @param mode string
--- @param map table
--- @return nil
function M.restore_buf_keymap(buf, mode, map)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.mapset(mode, false, map)
  end)
end

return M
