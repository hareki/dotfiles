local M = {}
local last_queries = {
  -- Key by picker "source" name; add more (e.g. files, grep_word) if needed
  grep = '',
  files = '',
}

local wrap_picker = function(source_name, base_fn)
  return function(opts)
    opts = opts or {}
    local defaults = require('snacks.picker.config.sources')[source_name]
    local is_live = (opts.live ~= nil) and opts.live or (defaults and defaults.live) or false

    if is_live and opts.search == nil then
      opts.search = function()
        return last_queries[source_name] or ''
      end
    elseif not is_live and opts.pattern == nil then
      opts.pattern = function()
        return last_queries[source_name] or ''
      end
    end

    local orig_on_close = opts.on_close
    opts.on_close = function(picker)
      -- For live pickers (grep defaults live=true) the active text is in `search`
      -- For non-live ones you'd read picker.input.filter.pattern instead
      local f = picker.input and picker.input.filter
      if f then
        local val = picker.opts.live and f.search or f.pattern
        last_queries[source_name] = val
      end
      if orig_on_close then
        pcall(orig_on_close, picker)
      end
    end

    return base_fn(opts)
  end
end

local pickers = { 'grep', 'files', 'buffers' }
for _, name in ipairs(pickers) do
  M[name] = wrap_picker(name, Snacks.picker[name])
end

return M
