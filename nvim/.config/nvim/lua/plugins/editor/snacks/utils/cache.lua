---@class plugins.editor.snacks.utils.cache
---@field cache table<string, any> Cached query results keyed by lhs:mode:buffer
local M = {}

M.cache = {}

-- Set up autocmd to clean up cache entries when buffers are deleted
vim.api.nvim_create_autocmd('BufDelete', {
  group = vim.api.nvim_create_augroup('snacks_utils_cache_cleanup', { clear = true }),
  callback = function(event)
    local buf_pattern = ':' .. event.buf .. '$'
    for key in pairs(M.cache) do
      if key:match(buf_pattern) then
        M.cache[key] = nil
      end
    end
  end,
})

return M
