--- @class features.preview.render-markdown.utils
local M = {}

--- Evict wiped buffers from render-markdown.nvim's bufnr-keyed caches, which never evict, so
--- short-lived markdown buffers leak tens of KB and a uv timer each; never loads the plugin
--- @param wiping? integer A buffer being wiped, still valid until its BufWipeout ends
--- @return nil
function M.evict_wiped_buffers(wiping)
  local function is_gone(bufnr)
    return bufnr == wiping or not vim.api.nvim_buf_is_valid(bufnr)
  end

  for _, name in ipairs({
    'render-markdown.state',
    'render-markdown.core.ui',
    'render-markdown.request.context',
  }) do
    local mod = package.loaded[name]
    if mod and type(mod.cache) == 'table' then
      for bufnr, entry in pairs(mod.cache) do
        if is_gone(bufnr) then
          -- core.ui's decorators each own a uv timer, which libuv keeps alive until closed
          if name == 'render-markdown.core.ui' then
            entry.timer:close()
          end
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
