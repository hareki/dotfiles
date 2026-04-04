---@class plugins.core.snacks.utils.cache
---@field cache table<string, any> Cached query results keyed by lhs:mode:buffer
local M = {}

M.cache = {}

-- Reverse index: bufnr -> list of cache keys for O(1) cleanup
local buf_keys = {}

---Store a value in the cache with buffer-aware indexing
---@param key string Cache key in the format "lhs:mode:bufnr"
---@param bufnr integer Buffer number
---@param value any Value to cache
function M.set(key, bufnr, value)
  M.cache[key] = value
  if not buf_keys[bufnr] then
    buf_keys[bufnr] = {}
  end
  buf_keys[bufnr][key] = true
end

vim.api.nvim_create_autocmd('BufDelete', {
  group = vim.api.nvim_create_augroup('snacks_utils_cache_cleanup', { clear = true }),
  callback = function(event)
    local keys = buf_keys[event.buf]
    if keys then
      for key in pairs(keys) do
        M.cache[key] = nil
      end
      buf_keys[event.buf] = nil
    end
  end,
})

return M
