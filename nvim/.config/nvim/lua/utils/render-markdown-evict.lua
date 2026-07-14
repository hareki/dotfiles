--- @class utils.render-markdown-evict
local M = {}

--- Evict a buffer's entries from render-markdown.nvim's per-buffer state.
--- The plugin keeps a config cache, a ui cache, and an attached-buffer list
--- keyed by bufnr with no eviction of its own, so short-lived markdown
--- buffers (notifications, tooltip popups) leak ~21KB each per session.
--- Only touches already-loaded modules; never triggers a plugin load.
--- @param bufnr integer
--- @return nil
function M.evict(bufnr)
  local state = package.loaded['render-markdown.state']
  if state and type(state.cache) == 'table' then
    state.cache[bufnr] = nil
  end

  local ui = package.loaded['render-markdown.core.ui']
  if ui and type(ui.cache) == 'table' then
    ui.cache[bufnr] = nil
  end

  local manager = package.loaded['render-markdown.core.manager']
  if manager and type(manager.buffers) == 'table' then
    for index, buf in ipairs(manager.buffers) do
      if buf == bufnr then
        table.remove(manager.buffers, index)
        break
      end
    end
  end
end

return M
