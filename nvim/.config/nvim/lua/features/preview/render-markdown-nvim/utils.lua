--- @class features.preview.render-markdown-nvim.utils
local M = {}

--- The cells of background on each side of a heading. The plugin ends the right ones at a window
--- column, so whoever paints its marks somewhere else (a picker row) adds those itself
M.HEADING_PAD = 1

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

--- The marks render-markdown would paint on a buffer, in this call: `render` paints a window a
--- tick later, too late for a picker row. Reads private modules: nothing public returns marks
--- @param buf integer
--- @return render.md.Mark[]
function M.marks(buf)
  local state = require('render-markdown.state')
  local Context = require('render-markdown.request.context')
  local handlers = require('render-markdown.core.handlers')

  -- The plugin parses around the windows showing the buffer; buf_call lends a hidden one a window
  return vim.api.nvim_buf_call(buf, function()
    local parser = assert(vim.treesitter.get_parser(buf, 'markdown'))
    local win = vim.api.nvim_get_current_win()
    local context = assert(Context.new(buf, win, state.get(buf)))

    local marks
    context.view:parse(parser, function()
      marks = handlers.run(context, parser)
    end)
    return marks
  end)
end

--- The plugin disables markdown's `conceal_lines` patterns, but the query still reports them, so
--- each height lookup after an edit (satellite's, per refresh) re-runs it per row for nothing
--- @return nil
function M.skip_conceal_line_pass()
  local query = vim.treesitter.query.get('markdown', 'highlights')
  if query then
    query.has_conceal_line = false
  end
end

--- Hiding or showing a line (a code fence) moves no topline, so no WinScrolled refreshes the bar
--- satellite.nvim measured, and a float that now fits keeps it; never loads the plugin
--- @param ctx render.md.on.render.Context render-markdown's `on.render` and `on.clear` argument
--- @return nil
function M.refresh_scrollbar(ctx)
  local visible = package.loaded['satellite.visible']
  if visible then
    visible.refresh_if_changed(ctx.win)
  end
end

return M
