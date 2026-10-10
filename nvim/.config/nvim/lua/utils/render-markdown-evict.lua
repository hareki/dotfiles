--- @class utils.render-markdown-evict
local M = {}

--- Evict wiped buffers from render-markdown.nvim's per-buffer state.
--- The plugin keeps a config cache, a ui cache, and an attached-buffer list
--- keyed by bufnr with no eviction of its own, so short-lived markdown
--- buffers (notifications, tooltip popups, previews) leak ~21KB each per session.
--- Buffer numbers are never reused, so a wiped buffer's entries can always go.
--- Only touches already-loaded modules; never triggers a plugin load.
--- @param wiping? integer A buffer being wiped, still valid until its BufWipeout ends
--- @return nil
function M.sweep(wiping)
  local function is_gone(bufnr)
    return bufnr == wiping or not vim.api.nvim_buf_is_valid(bufnr)
  end

  for _, name in ipairs({ 'render-markdown.state', 'render-markdown.core.ui' }) do
    local mod = package.loaded[name]
    if mod and type(mod.cache) == 'table' then
      for bufnr in pairs(mod.cache) do
        if is_gone(bufnr) then
          mod.cache[bufnr] = nil
        end
      end
    end
  end

  local manager = package.loaded['render-markdown.core.manager']
  if manager and type(manager.buffers) == 'table' then
    for index = #manager.buffers, 1, -1 do
      if is_gone(manager.buffers[index]) then
        table.remove(manager.buffers, index)
      end
    end
  end
end

return M
